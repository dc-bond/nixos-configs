{ 
  pkgs, 
  config,
  ...
}:

let

  borgCypressCryptPasswdFile = "/run/secrets/borgCypressCryptPasswd";

  listCypressArchivesScript = pkgs.writeShellScriptBin "listCypressArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
    sudo -E ${pkgs.borgbackup}/bin/borg list ${config.backups.borgCypressRepo} 
    '';

  infoCypressArchivesScript = pkgs.writeShellScriptBin "infoCypressArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
    sudo -E ${pkgs.borgbackup}/bin/borg info ${config.backups.borgCypressRepo} 
    '';

  recoverLldapScript = pkgs.writeShellScriptBin "recoverlldap" ''
    #!/bin/bash
  
    # enable tracing of commands
    set -x

    # helper function to print styled messages
    log() {
      # temporarily disable tracing for this function
      { set +x; } 2>/dev/null
      echo -e "\033[1;33m$1\033[0m"
      { set -x; } 2>/dev/null
    }

    # obtain target host from user
    read -p "Enter hostname to recover: " HOST
    if [ -z "$HOST" ]; then
      echo "Error: host required."
      exit 1
    fi
    
    # obtain target archive from user
    read -p "Enter the archive to recover: " ARCHIVE
    if [ -z "$ARCHIVE" ]; then
      echo "Error: archive required."
      exit 1
    fi

    # set borg passphrase environment variable
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})

    { set +x; log "starting backup recovery for lldap on $HOST"; } 2>/dev/null

    { set +x; log "changing directory to ${config.backups.borgRestoreDir}"; } 2>/dev/null
    cd ${config.backups.borgRestoreDir}

    { set +x; log "extracting application data for lldap from borg repository"; } 2>/dev/null
    sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgRestoreDir}/$HOST::$ARCHIVE var/lib/private/lldap --strip-components 3

    { set +x; log "changing ownership of extracted application data"; } 2>/dev/null
    sudo chown -R chris:users ${config.backups.borgRestoreDir}/lldap

    { set +x; log "stopping lldap.service on $HOST"; } 2>/dev/null
    ssh $HOST 'sudo systemctl stop lldap.service'

    { set +x; log "removing existing application data on $HOST"; } 2>/dev/null
    ssh $HOST 'sudo rm -rf /var/lib/lldap'
    ssh $HOST 'sudo rm -rf /var/lib/private/lldap'

    { set +x; log "transferring restored data to $HOST"; } 2>/dev/null
    rsync --progress -avzh ${config.backups.borgRestoreDir}/lldap $HOST:/tmp
    ssh $HOST 'sudo mv /tmp/lldap /var/lib/private'
    ssh $HOST 'sudo chown -R lldap:lldap /var/lib/private/lldap'

    { set +x; log "cleaning up local restore directory"; } 2>/dev/null
    sudo rm -rf ${config.backups.borgRestoreDir}/lldap

    { set +x; log "restoring PostgreSQL backup for lldap"; } 2>/dev/null
    sudo borg extract --verbose --list ${borgRepo}::$ARCHIVE var/backup/postgresql/lldap.sql.gz --strip-components 3
    sudo mv ${config.backups.borgRestoreDir}/lldap.sql.gz /home/chris
    sudo chown chris:users /home/chris/lldap.sql.gz
    rsync --progress -avzh /home/chris/lldap.sql.gz $HOST:/tmp
    ssh $HOST 'sudo gunzip -c /tmp/lldap.sql.gz > /tmp/lldap.sql'
    ssh $HOST 'sudo chown postgres:postgres /tmp/lldap.sql'
    ssh $HOST 'sudo mv /tmp/lldap.sql /var/lib/postgresql'
    ssh $HOST 'sudo rm -rf /tmp/lldap.sql.gz'
    ssh $HOST 'sudo -u postgres psql -U postgres -d template1 -c "DROP DATABASE \"lldap\";"'
    ssh $HOST 'sudo -u postgres psql -U postgres -d template1 -c "CREATE DATABASE \"lldap\" OWNER \"lldap\";"'
    ssh $HOST 'sudo -u postgres psql -U postgres -d lldap -f /var/lib/postgresql/lldap.sql'
    ssh $HOST 'sudo rm -rf /var/lib/postgresql/lldap.sql'
    rm -rf /home/chris/lldap.sql.gz

    { set +x; log "rebuilding NixOS configuration for $HOST"; } 2>/dev/null
    nixos-rebuild \
      --flake ~/nixos-configs#$HOST \
      --target-host $HOST \
      --use-remote-sudo \
      --verbose \
      switch
    '';

in

{

  sops.secrets.borgCypressCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    listCypressArchivesScript
    infoCypressArchivesScript
    #recoverCypressLldapScript
  ];

}  