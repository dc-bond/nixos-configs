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
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    sudo -E ${pkgs.borgbackup}/bin/borg list ${config.backups.borgDir}/cypress
    '';

  infoCypressArchivesScript = pkgs.writeShellScriptBin "infoCypressArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    sudo -E ${pkgs.borgbackup}/bin/borg info ${config.backups.borgDir}/cypress
    '';

   recoverCypressTraefikScript = pkgs.writeShellScriptBin "recoverCypressTraefik" ''
    #!/bin/bash

    # track errors
    set -e
    set -o pipefail
    
    # helper function to print styled messages
    log() {
      # temporarily disable tracing for this function
      { set +x; } 2>/dev/null
      echo -e "\033[1;33m$1\033[0m"
      { set -x; } 2>/dev/null
    }
    
    # set borg passphrase environment variable
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
  
    # obtain target archive from user
    read -p "Enter the archive to recover: " ARCHIVE
    if [ -z "$ARCHIVE" ]; then
      error "Archive required."
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

    { set +x; log "starting backup recovery for traefik on cypress"; } 2>/dev/null

    { set +x; log "changing directory to ${config.backups.borgDir}"; } 2>/dev/null
    cd ${config.backups.borgDir}

    { set +x; log "extracting application data for traefik from borg repository"; } 2>/dev/null
    sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/cypress::$ARCHIVE var/lib/traefik --strip-components 2

    { set +x; log "changing ownership of extracted application data"; } 2>/dev/null
    sudo chown -R chris:users ${config.backups.borgDir}/traefik

    { set +x; log "stopping traefik service on cypress"; } 2>/dev/null
    ssh cypress 'sudo systemctl stop traefik.service'

    { set +x; log "removing existing application data on cypress"; } 2>/dev/null
    ssh cypress 'sudo rm -rf /var/lib/traefik'

    { set +x; log "transferring restored data to cypress"; } 2>/dev/null
    rsync --progress -avzh ${config.backups.borgDir}/traefik cypress:/tmp
    ssh cypress 'sudo mv /tmp/traefik /var/lib'
    
    { set +x; log "changing ownership of restored application data"; } 2>/dev/null
    ssh cypress 'sudo chown -R traefik:traefik /var/lib/traefik'

    { set +x; log "cleaning up local restore directory"; } 2>/dev/null
    sudo rm -rf ${config.backups.borgDir}/traefik

    { set +x; log "restarting restored traefik service on cypress"; } 2>/dev/null
    ssh cypress 'sudo systemctl start traefik.service'
    '';
   
  recoverCypressHomeassistantScript = pkgs.writeShellScriptBin "recoverCypressHomeassistant" ''
    #!/bin/bash

    # track errors
    set -e
    set -o pipefail
    
    # helper function to print styled messages
    log() {
      # temporarily disable tracing for this function
      { set +x; } 2>/dev/null
      echo -e "\033[1;33m$1\033[0m"
      { set -x; } 2>/dev/null
    }
    
    # set borg passphrase environment variable
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
  
    # obtain target archive from user
    read -p "Enter the archive to recover: " ARCHIVE
    if [ -z "$ARCHIVE" ]; then
      error "Archive required."
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

    { set +x; log "starting backup recovery for homeassistant on cypress"; } 2>/dev/null

    { set +x; log "changing directory to ${config.backups.borgDir}"; } 2>/dev/null
    cd ${config.backups.borgDir}

    { set +x; log "extracting application data for homeassistant from borg repository"; } 2>/dev/null
    sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/cypress::$ARCHIVE var/lib/hass --strip-components 2

    { set +x; log "changing ownership of extracted application data"; } 2>/dev/null
    sudo chown -R chris:users ${config.backups.borgDir}/hass

    { set +x; log "stopping homeassistant service on cypress"; } 2>/dev/null
    ssh cypress 'sudo systemctl stop home-assistant.service'

    { set +x; log "removing existing application data on cypress"; } 2>/dev/null
    ssh cypress 'sudo rm -rf /var/lib/hass'

    { set +x; log "transferring restored data to cypress"; } 2>/dev/null
    rsync --progress -avzh ${config.backups.borgDir}/hass cypress:/tmp
    ssh cypress 'sudo mv /tmp/hass /var/lib'
    
    { set +x; log "changing ownership of restored application data"; } 2>/dev/null
    ssh cypress 'sudo chown -R hass:hass /var/lib/hass'

    { set +x; log "cleaning up local restore directory"; } 2>/dev/null
    sudo rm -rf ${config.backups.borgDir}/hass

    { set +x; log "restoring PostgreSQL backup for homeassistant"; } 2>/dev/null
    sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/cypress::$ARCHIVE var/backup/postgresql/hass.sql.gz --strip-components 3
    sudo chown chris:users ${config.backups.borgDir}/hass.sql.gz
    rsync --progress -avzh ${config.backups.borgDir}/hass.sql.gz cypress:/tmp
    ssh cypress 'sudo gunzip -c /tmp/hass.sql.gz > /tmp/hass.sql'
    ssh cypress 'sudo chown postgres:postgres /tmp/hass.sql'
    ssh cypress 'sudo mv /tmp/hass.sql /var/lib/postgresql'
    ssh cypress 'sudo rm -rf /tmp/hass.sql.gz'
    ssh cypress 'sudo -u postgres psql -U postgres -d template1 -c "DROP DATABASE \"hass\";"'
    ssh cypress 'sudo -u postgres psql -U postgres -d template1 -c "CREATE DATABASE \"hass\" OWNER \"hass\";"'
    ssh cypress 'sudo -u postgres psql -U postgres -d hass -f /var/lib/postgresql/hass.sql'
    ssh cypress 'sudo rm -rf /var/lib/postgresql/hass.sql'
    sudo rm -rf ${config.backups.borgDir}/hass.sql.gz

    { set +x; log "restarting restored homeassistant service on cypress"; } 2>/dev/null
    ssh cypress 'sudo systemctl start home-assistant.service'
    '';

  recoverCypressNextcloudScript = pkgs.writeShellScriptBin "recoverCypressNextcloud" ''
    #!/bin/bash

    # track errors
    set -e
    set -o pipefail
    
    # helper function to print styled messages
    log() {
      # temporarily disable tracing for this function
      { set +x; } 2>/dev/null
      echo -e "\033[1;33m$1\033[0m"
      { set -x; } 2>/dev/null
    }
    
    # set borg passphrase environment variable
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
  
    # obtain target archive from user
    read -p "Enter the archive to recover: " ARCHIVE
    if [ -z "$ARCHIVE" ]; then
      error "Archive required."
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

    { set +x; log "starting backup recovery for nextcloud on cypress"; } 2>/dev/null

    { set +x; log "changing directory to ${config.backups.borgDir}"; } 2>/dev/null
    cd ${config.backups.borgDir}

    { set +x; log "extracting application data for nextcloud from borg repository"; } 2>/dev/null
    sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/cypress::$ARCHIVE var/lib/nextcloud --strip-components 2
    sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/cypress::$ARCHIVE var/lib/redis-nextcloud --strip-components 2

    { set +x; log "changing ownership of extracted application data"; } 2>/dev/null
    sudo chown -R chris:users ${config.backups.borgDir}/nextcloud
    sudo chown -R chris:users ${config.backups.borgDir}/redis-nextcloud

    { set +x; log "stopping nextcloud stack on cypress"; } 2>/dev/null
    ssh cypress 'nextcloud-occ maintenance:mode --on'
    ssh cypress 'sudo systemctl stop redis-nextcloud.service'
    ssh cypress 'sudo systemctl stop nginx.service'

    { set +x; log "removing existing application data on cypress"; } 2>/dev/null
    ssh cypress 'sudo rm -rf /var/lib/nextcloud'
    ssh cypress 'sudo rm -rf /var/lib/redis-nextcloud'

    { set +x; log "transferring restored data to cypress"; } 2>/dev/null
    rsync --progress -avzh ${config.backups.borgDir}/nextcloud cypress:/tmp
    rsync --progress -avzh ${config.backups.borgDir}/redis-nextcloud cypress:/tmp
    ssh cypress 'sudo mv /tmp/nextcloud /var/lib'
    ssh cypress 'sudo mv /tmp/redis-nextcloud /var/lib'

    { set +x; log "changing ownership of restored application data"; } 2>/dev/null
    ssh cypress 'sudo chown -R nextcloud:nextcloud /var/lib/nextcloud'
    ssh cypress 'sudo chown -R nextcloud:nextcloud /var/lib/redis-nextcloud'

    { set +x; log "cleaning up local restore directory"; } 2>/dev/null
    sudo rm -rf ${config.backups.borgDir}/nextcloud
    sudo rm -rf ${config.backups.borgDir}/redis-nextcloud

    { set +x; log "restoring PostgreSQL backup for nextcloud"; } 2>/dev/null
    sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/cypress::$ARCHIVE var/backup/postgresql/nextcloud.sql.gz --strip-components 3
    sudo chown chris:users ${config.backups.borgDir}/nextcloud.sql.gz
    rsync --progress -avzh ${config.backups.borgDir}/nextcloud.sql.gz cypress:/tmp
    ssh cypress 'sudo gunzip -c /tmp/nextcloud.sql.gz > /tmp/nextcloud.sql'
    ssh cypress 'sudo chown postgres:postgres /tmp/nextcloud.sql'
    ssh cypress 'sudo mv /tmp/nextcloud.sql /var/lib/postgresql'
    ssh cypress 'sudo rm -rf /tmp/nextcloud.sql.gz'
    ssh cypress 'sudo -u postgres psql -U postgres -d template1 -c "DROP DATABASE \"nextcloud\";"'
    ssh cypress 'sudo -u postgres psql -U postgres -d template1 -c "CREATE DATABASE \"nextcloud\" OWNER \"nextcloud\";"'
    ssh cypress 'sudo -u postgres psql -U postgres -d nextcloud -f /var/lib/postgresql/nextcloud.sql'
    ssh cypress 'sudo rm -rf /var/lib/postgresql/nextcloud.sql'
    sudo rm -rf ${config.backups.borgDir}/nextcloud.sql.gz

    { set +x; log "restarting restored nextcloud service on cypress"; } 2>/dev/null
    ssh cypress 'sudo systemctl start redis-nextcloud.service'
    ssh cypress 'sudo systemctl start nginx.service'
    '';

  recoverCypressUptimeKumaScript = pkgs.writeShellScriptBin "recoverCypressUptimeKuma" ''
    #!/bin/bash

    # track errors
    set -e
    set -o pipefail

    # helper function to print styled messages
    log() {
      # temporarily disable tracing for this function
      { set +x; } 2>/dev/null
      echo -e "\033[1;33m$1\033[0m"
      { set -x; } 2>/dev/null
    }
    
    # set borg passphrase environment variable
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
  
    # obtain target archive from user
    read -p "Enter the archive to recover: " ARCHIVE
    if [ -z "$ARCHIVE" ]; then
      error "Archive required."
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

    { set +x; log "starting backup recovery for uptime-kuma on cypress"; } 2>/dev/null

    { set +x; log "changing directory to ${config.backups.borgDir}"; } 2>/dev/null
    cd ${config.backups.borgDir}

    { set +x; log "extracting application data from borg repository"; } 2>/dev/null
    sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/cypress::$ARCHIVE var/lib/private/uptime-kuma --strip-components 3

    { set +x; log "changing ownership of extracted application data"; } 2>/dev/null
    sudo chown -R chris:users ${config.backups.borgDir}/uptime-kuma

    { set +x; log "stopping uptime-kuma.service on cypress"; } 2>/dev/null
    ssh cypress 'sudo systemctl stop uptime-kuma.service'

    { set +x; log "removing existing application data on cypress"; } 2>/dev/null
    ssh cypress 'sudo rm -rf /var/lib/uptime-kuma'
    ssh cypress 'sudo rm -rf /var/lib/private/uptime-kuma'

    { set +x; log "transferring restored data to cypress"; } 2>/dev/null
    rsync --progress -avzh ${config.backups.borgDir}/uptime-kuma cypress:/tmp
    ssh cypress 'sudo mv /tmp/uptime-kuma /var/lib/private'

    { set +x; log "cleaning up local restore directory"; } 2>/dev/null
    sudo rm -rf ${config.backups.borgDir}/uptime-kuma

    { set +x; log "restarting restored uptime-kuma service on cypress"; } 2>/dev/null
    ssh cypress 'sudo systemctl start uptime-kuma.service'
    '';
    
  recoverCypressLldapScript = pkgs.writeShellScriptBin "recoverCypressLldap" ''
    #!/bin/bash

    # track errors
    set -e
    set -o pipefail

    # helper function to print styled messages
    log() {
      # temporarily disable tracing for this function
      { set +x; } 2>/dev/null
      echo -e "\033[1;33m$1\033[0m"
      { set -x; } 2>/dev/null
    }
    
    # set borg passphrase environment variable
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
  
    # obtain target archive from user
    read -p "Enter the archive to recover: " ARCHIVE
    if [ -z "$ARCHIVE" ]; then
      error "Archive required."
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
    
    # track errors
    set -e
    set -o pipefail
    
    # set borg passphrase environment variable
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
  
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

  recoverCypressActualScript = pkgs.writeShellScriptBin "recoverCypressActual" ''
    #!/bin/bash
    
    # track errors
    set -e
    set -o pipefail
    
    # set borg passphrase environment variable
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
  
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

    { set +x; log "starting backup recovery for actual container on cypress"; } 2>/dev/null

    { set +x; log "changing directory to ${config.backups.borgDir}"; } 2>/dev/null
    cd ${config.backups.borgDir}

    { set +x; log "extracting application data from borg repository"; } 2>/dev/null
    sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/cypress::$ARCHIVE var/lib/docker/volumes/actual --strip-components 4
    
    { set +x; log "changing ownership of extracted application data"; } 2>/dev/null
    sudo chown -R chris:users ${config.backups.borgDir}/actual

    { set +x; log "stopping actual container stack on cypress"; } 2>/dev/null
    ssh cypress 'sudo systemctl stop docker-actual-root.target'

    { set +x; log "removing existing application data on cypress"; } 2>/dev/null
    ssh cypress 'sudo rm -rf /var/lib/docker/volumes/actual'

    { set +x; log "transferring restored data to cypress"; } 2>/dev/null
    rsync --progress -avzh ${config.backups.borgDir}/actual cypress:/tmp
    ssh cypress 'sudo mv /tmp/actual /var/lib/docker/volumes'
    
    { set +x; log "changing ownership of restored application data"; } 2>/dev/null
    ssh cypress 'sudo chown -R root:root /var/lib/docker/volumes/actual'

    { set +x; log "cleaning up local restore directory"; } 2>/dev/null
    sudo rm -rf ${config.backups.borgDir}/actual

    { set +x; log "restarting restored actual container stack on cypress"; } 2>/dev/null
    ssh cypress 'sudo systemctl start docker-actual-root.target'
    '';
    
  recoverCypressZwavejsScript = pkgs.writeShellScriptBin "recoverCypressZwavejs" ''
    #!/bin/bash
    
    # track errors
    set -e
    set -o pipefail
    
    # set borg passphrase environment variable
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
  
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
    recoverCypressUptimeKumaScript
    recoverCypressPiholeScript
    recoverCypressZwavejsScript
    recoverCypressActualScript
    recoverCypressNextcloudScript
    recoverCypressTraefikScript
    recoverCypressHomeassistantScript
  ];

}  