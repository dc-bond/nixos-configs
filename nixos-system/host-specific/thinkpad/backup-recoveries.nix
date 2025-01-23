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
    sudo -E ${pkgs.borgbackup}/bin/borg list ${config.backups.borgDir}/cypress
    '';

  infoCypressArchivesScript = pkgs.writeShellScriptBin "infoCypressArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
    sudo -E ${pkgs.borgbackup}/bin/borg info ${config.backups.borgDir}/cypress
    '';

  recoverCypressLldapScript = pkgs.writeShellScriptBin "recoverCypressLldap" ''
    #!/bin/bash

    # set borg passphrase environment variable
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
  
    # obtain target archive from user
    read -p "Enter the archive to recover: " ARCHIVE
    if [ -z "$ARCHIVE" ]; then
      echo "Error: archive required."
      exit 1
    fi

    # helper function to print styled messages
    log() {
      # temporarily disable tracing for this function
      { set +x; } 2>/dev/null
      echo -e "\033[1;33m$1\033[0m"
      { set -x; } 2>/dev/null
    }

    # enable tracing of commands
    set -x

    { set +x; log "starting backup recovery for lldap on cypress"; } 2>/dev/null

    { set +x; log "changing directory to ${config.backups.borgDir}"; } 2>/dev/null
    cd ${config.backups.borgDir}

    { set +x; log "extracting application data for lldap from borg repository"; } 2>/dev/null
    sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/cypress::$ARCHIVE var/lib/private/lldap --strip-components 3

    { set +x; log "changing ownership of extracted application data"; } 2>/dev/null
    sudo chown -R chris:users ${config.backups.borgDir}/lldap

    { set +x; log "stopping lldap.service on cypress"; } 2>/dev/null
    ssh cypress 'sudo systemctl stop lldap.service'

    { set +x; log "removing existing application data on cypress"; } 2>/dev/null
    ssh cypress 'sudo rm -rf /var/lib/lldap'
    ssh cypress 'sudo rm -rf /var/lib/private/lldap'

    { set +x; log "transferring restored data to cypress"; } 2>/dev/null
    rsync --progress -avzh ${config.backups.borgDir}/lldap cypress:/tmp
    ssh cypress 'sudo mv /tmp/lldap /var/lib/private'

    { set +x; log "cleaning up local restore directory"; } 2>/dev/null
    sudo rm -rf ${config.backups.borgDir}/lldap

    { set +x; log "restoring PostgreSQL backup for lldap"; } 2>/dev/null
    sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/cypress::$ARCHIVE var/backup/postgresql/lldap.sql.gz --strip-components 3
    sudo chown chris:users ${config.backups.borgDir}/lldap.sql.gz
    rsync --progress -avzh ${config.backups.borgDir}/lldap.sql.gz cypress:/tmp
    ssh cypress 'sudo gunzip -c /tmp/lldap.sql.gz > /tmp/lldap.sql'
    ssh cypress 'sudo chown postgres:postgres /tmp/lldap.sql'
    ssh cypress 'sudo mv /tmp/lldap.sql /var/lib/postgresql'
    ssh cypress 'sudo rm -rf /tmp/lldap.sql.gz'
    ssh cypress 'sudo -u postgres psql -U postgres -d template1 -c "DROP DATABASE \"lldap\";"'
    ssh cypress 'sudo -u postgres psql -U postgres -d template1 -c "CREATE DATABASE \"lldap\" OWNER \"lldap\";"'
    ssh cypress 'sudo -u postgres psql -U postgres -d lldap -f /var/lib/postgresql/lldap.sql'
    ssh cypress 'sudo rm -rf /var/lib/postgresql/lldap.sql'
    sudo rm -rf ${config.backups.borgDir}/lldap.sql.gz

    { set +x; log "restarting restored lldap service on cypress"; } 2>/dev/null
    ssh cypress 'sudo systemctl start lldap.service'
    '';

  recoverCypressPiholeScript = pkgs.writeShellScriptBin "recoverCypressPihole" ''
    #!/bin/bash
    
    # set borg passphrase environment variable
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
  
    # obtain target archive from user
    read -p "Enter the archive to recover: " ARCHIVE
    if [ -z "$ARCHIVE" ]; then
      echo "Error: archive required."
      exit 1
    fi
    
    # helper function to print styled messages
    log() {
      # temporarily disable tracing for this function
      { set +x; } 2>/dev/null
      echo -e "\033[1;33m$1\033[0m"
      { set -x; } 2>/dev/null
    }
    
    # enable tracing of commands
    set -x

    { set +x; log "starting backup recovery for pihole-unbound containers on cypress"; } 2>/dev/null

    { set +x; log "changing directory to ${config.backups.borgDir}"; } 2>/dev/null
    cd ${config.backups.borgDir}

    { set +x; log "extracting application data for pihole from borg repository"; } 2>/dev/null
    sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/cypress::$ARCHIVE var/lib/docker/volumes/pihole --strip-components 4

    { set +x; log "extracting application data for unbound from borg repository"; } 2>/dev/null
    sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/cypress::$ARCHIVE var/lib/docker/volumes/unbound --strip-components 4

    { set +x; log "changing ownership of extracted application data"; } 2>/dev/null
    sudo chown -R chris:users ${config.backups.borgDir}/pihole
    sudo chown -R chris:users ${config.backups.borgDir}/unbound

    { set +x; log "stopping pihole-unbound container stack on cypress"; } 2>/dev/null
    ssh cypress 'sudo systemctl stop docker-pihole-root.target'

    { set +x; log "removing existing application data on cypress"; } 2>/dev/null
    ssh cypress 'sudo rm -rf /var/lib/docker/volumes/pihole'
    ssh cypress 'sudo rm -rf /var/lib/docker/volumes/unbound'

    { set +x; log "transferring restored data to cypress"; } 2>/dev/null
    rsync --progress -avzh ${config.backups.borgDir}/pihole cypress:/tmp
    rsync --progress -avzh ${config.backups.borgDir}/unbound cypress:/tmp
    ssh cypress 'sudo mv /tmp/pihole /var/lib/docker/volumes'
    ssh cypress 'sudo mv /tmp/unbound /var/lib/docker/volumes'

    { set +x; log "changing ownership of restored application data"; } 2>/dev/null
    ssh cypress 'sudo chown -R root:root /var/lib/docker/volumes/pihole'
    ssh cypress 'sudo chown -R root:root /var/lib/docker/volumes/unbound'

    { set +x; log "cleaning up local restore directory"; } 2>/dev/null
    sudo rm -rf ${config.backups.borgDir}/pihole
    sudo rm -rf ${config.backups.borgDir}/unbound

    { set +x; log "restarting restored pihole-unbound container stack on cypress"; } 2>/dev/null
    ssh cypress 'sudo systemctl start docker-pihole-root.target'
    '';

  recoverCypressZwavejsScript = pkgs.writeShellScriptBin "recoverCypressZwavejs" ''
    #!/bin/bash
    
    # set borg passphrase environment variable
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
  
    # obtain target archive from user
    read -p "Enter the archive to recover: " ARCHIVE
    if [ -z "$ARCHIVE" ]; then
      echo "Error: archive required."
      exit 1
    fi
    
    # helper function to print styled messages
    log() {
      # temporarily disable tracing for this function
      { set +x; } 2>/dev/null
      echo -e "\033[1;33m$1\033[0m"
      { set -x; } 2>/dev/null
    }
    
    # enable tracing of commands
    set -x

    { set +x; log "starting backup recovery for zwavejs container on cypress"; } 2>/dev/null

    { set +x; log "changing directory to ${config.backups.borgDir}"; } 2>/dev/null
    cd ${config.backups.borgDir}

    { set +x; log "extracting application data for zwavejs from borg repository"; } 2>/dev/null
    sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/cypress::$ARCHIVE var/lib/docker/volumes/zwavejs --strip-components 4
    
    { set +x; log "changing ownership of extracted application data"; } 2>/dev/null
    sudo chown -R chris:users ${config.backups.borgDir}/zwavejs

    { set +x; log "stopping zwavejs container stack on cypress"; } 2>/dev/null
    ssh cypress 'sudo systemctl stop docker-zwavejs-root.target'

    { set +x; log "removing existing application data on cypress"; } 2>/dev/null
    ssh cypress 'sudo rm -rf /var/lib/docker/volumes/zwavejs'

    { set +x; log "transferring restored data to cypress"; } 2>/dev/null
    rsync --progress -avzh ${config.backups.borgDir}/zwavejs cypress:/tmp
    ssh cypress 'sudo mv /tmp/zwavejs /var/lib/docker/volumes'
    
    { set +x; log "changing ownership of restored application data"; } 2>/dev/null
    ssh cypress 'sudo chown -R root:root /var/lib/docker/volumes/zwavejs'

    { set +x; log "cleaning up local restore directory"; } 2>/dev/null
    sudo rm -rf ${config.backups.borgDir}/zwavejs

    { set +x; log "restarting restored zwavejs container stack on cypress"; } 2>/dev/null
    ssh cypress 'sudo systemctl start docker-zwavejs-root.target'
    '';

in

{

  sops.secrets.borgCypressCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    listCypressArchivesScript
    infoCypressArchivesScript
    recoverCypressLldapScript
    recoverCypressPiholeScript
    recoverCypressZwavejsScript
  ];

}  