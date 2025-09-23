{ 
  pkgs, 
  lib,
  config,
  ...
}:

let

  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";

  restorePlan = {
    serviceName = "lldap";
    localRestoreRepoPath = "${config.backups.borgDir}/${config.networking.hostName}";
    cloudRestoreRepoPath = "${config.backups.borgCloudDir}/${config.networking.hostName}";
    restoreItems = [
      "/var/lib/private/lldap"
      "/var/backup/postgresql/hass.sql.gz"
    ];
    db = {
      user = "lldap";
      name = "lldap";
      dump = "/var/backup/postgresql/lldap.sql.gz";
    };
    permissions = [
      { path = "/var/lib/private/lldap"; owner = "lldap"; group = "lldap"; recursive = true; }
    ];
    stopServices = [ "lldap" ];
    startServices = [ "lldap" ];
  };

  recoverLldapScript = pkgs.writeShellScriptBin "recoverLldap" ''
    #!/bin/bash
   
    # track errors
    set -euo pipefail

    # set borg passphrase environment variable
    export BORG_PASSPHRASE=$(sudo cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

    REPO="${restorePlan.localRestoreRepoPath}"

    if [ -z "${ARCHIVE:-}" ]; then
      archive_names=($(sudo -E ${pkgs.borgbackup}/bin/borg list --short "$REPO"))
      echo "Available Archives:"
      select ARCHIVE in "${archive_names[@]}"; do
        if [[ -n "$ARCHIVE" ]]; then
          echo "Selected archive: $ARCHIVE"
          break
        else
          echo "Invalid selection."
        fi
      done
    fi

    # stop services
    for svc in ${lib.concatStringsSep " " restorePlan.stopServices}; do
      echo "Stopping $svc ..."
      sudo systemctl stop "$svc" || true
    done

    # extract data from archive and overwrite existing data
    echo "Extracting data from $REPO::$ARCHIVE ..."
    sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list "$REPO"::"$ARCHIVE" ${lib.concatStringsSep " " restorePlan.restoreItems}
    
    # ensure permissions are set correctly
    echo "Setting permissions on restored data ..."
    ${lib.concatMapStringsSep "\n"
      (perm: "sudo chown ${if perm.recursive then "-R " else ""}${perm.owner}:${perm.group} ${perm.path} || true")
      restorePlan.permissions
    }
    
    # drop and recreate database
    echo "Dropping and recreating clean database ${restorePlan.db.name} ..."
    sudo -u postgres dropdb --if-exists ${restorePlan.db.name}
    sudo -u postgres createdb -O ${restorePlan.db.user} ${restorePlan.db.name}
    
    # restore database from dump backup
    echo "Restoring database from ${restorePlan.db.dump} ..."
    sudo gunzip -c ${restorePlan.db.dump} | sudo -u postgres psql ${restorePlan.db.name}

    # start services
    for svc in ${lib.concatStringsSep " " restorePlan.startServices}; do
      echo "Starting $svc ..."
      sudo systemctl start "$svc" || true
    done

    echo "Restore complete. Check status with: sudo systemctl status ${restorePlan.serviceName}"
  '';

in

{

  sops.secrets.borgCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    recoverHomeassistantScript
  ];

}  