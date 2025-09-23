{ 
  pkgs, 
  lib,
  config,
  ...
}:

let

  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";

  recoveryPlan = {
    serviceName = "home-assistant";
    localRestoreRepoPath = "${config.backups.borgDir}/${config.networking.hostName}";
    cloudRestoreRepoPath = "${config.backups.borgCloudDir}/${config.networking.hostName}";
    restoreItems = [
      "/var/lib/hass"
      "/var/backup/postgresql/hass.sql.gz"
    ];
    db = {
      user = "hass";
      name = "hass";
      dump = "/var/backup/postgresql/hass.sql.gz";
    };
    permissions = [
      { path = "/var/lib/hass"; owner = "hass"; group = "hass"; recursive = true; }
    ];
    stopServices = [ "home-assistant" ];
    startServices = [ "home-assistant" ];
  };

  recoverHomeassistantScript = pkgs.writeShellScriptBin "recoverHomeassistant" ''
    #!/bin/bash
   
    # track errors
    set -euo pipefail

    # set borg passphrase environment variable
    export BORG_PASSPHRASE=$(sudo cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

    REPO="${recoveryPlan.localRestoreRepoPath}"

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
    for svc in ${lib.concatStringsSep " " recoveryPlan.stopServices}; do
      echo "Stopping $svc ..."
      sudo systemctl stop "$svc" || true
    done

    # extract data from archive and overwrite existing data
    echo "Extracting data from $REPO::$ARCHIVE ..."
    sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list "$REPO"::"$ARCHIVE" ${lib.concatStringsSep " " recoveryPlan.restoreItems}
    
    # ensure permissions are set correctly
    echo "Setting permissions on restored data ..."
    ${lib.concatMapStringsSep "\n"
      (perm: "sudo chown ${if perm.recursive then "-R " else ""}${perm.owner}:${perm.group} ${perm.path} || true")
      recoveryPlan.permissions
    }
    
    # drop and recreate database
    echo "Dropping and recreating database ${recoveryPlan.db.name} ..."
    sudo -u postgres dropdb --if-exists ${recoveryPlan.db.name}
    sudo -u postgres createdb -O ${recoveryPlan.db.user} ${recoveryPlan.db.name}
    
    # restore database from dump backup
    echo "Restoring database from ${recoveryPlan.db.dump} ..."
    sudo gunzip -c ${recoveryPlan.db.dump} | sudo -u postgres psql ${recoveryPlan.db.name}

    # start services
    for svc in ${lib.concatStringsSep " " recoveryPlan.startServices}; do
      echo "Starting $svc ..."
      sudo systemctl start "$svc" || true
    done

    echo "Restore complete. Check status with: sudo systemctl status ${recoveryPlan.serviceName}"
  '';

in

{

  sops.secrets.borgCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    recoverHomeassistantScript
  ];

}  