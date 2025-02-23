{ 
  pkgs, 
  config,
  ...
}:

let

  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";

  recoverHomeassistantScript = pkgs.writeShellScriptBin "recoverHomeassistant" ''
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
   export BORG_PASSPHRASE=$(sudo cat ${borgCryptPasswdFile})
   export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

   # define available hosts
   HOSTS=("aspen", "cypress" "thinkpad")
   
   # display menu options for hosts
   echo "Select a host to recover to:"
   for i in "''${!HOSTS[@]}"; do
     echo "$((i+1))) ''${HOSTS[$i]}"
   done
   
   # obtain target host from user
   read -p "Enter the number of your choice for a host: " CHOICE
   
   # validate host selection
   if [[ ! "$CHOICE" =~ ^[1-3]$ ]]; then
     echo "Error: Invalid selection."
     exit 1
   fi
   
   # set the selected host
   HOST="''${HOSTS[$((CHOICE-1))]}"
  
   # obtain target archive from user
   read -p "Enter the archive to recover: " ARCHIVE
   if [ -z "$ARCHIVE" ]; then
     echo "Error: Archive required."
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

   { set +x; log "starting backup recovery for homeassistant"; } 2>/dev/null

   { set +x; log "changing directory to ${config.backups.borgDir}"; } 2>/dev/null
   cd ${config.backups.borgDir}

   { set +x; log "extracting application data from borg repository"; } 2>/dev/null
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/$HOST::$ARCHIVE var/lib/hass --strip-components 2

   { set +x; log "changing ownership of extracted application data"; } 2>/dev/null
   sudo chown -R chris:users ${config.backups.borgDir}/hass

   { set +x; log "stopping homeassistant service on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo systemctl stop home-assistant.service'

   { set +x; log "removing existing application data on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo rm -rf /var/lib/hass'

   { set +x; log "transferring restored data to $HOST"; } 2>/dev/null
   rsync --progress -avzh ${config.backups.borgDir}/hass $HOST:/tmp
   ssh $HOST 'sudo mv /tmp/hass /var/lib'
   
   { set +x; log "changing ownership of restored application data"; } 2>/dev/null
   ssh $HOST 'sudo chown -R hass:hass /var/lib/hass'

   { set +x; log "cleaning up local restore directory"; } 2>/dev/null
   sudo rm -rf ${config.backups.borgDir}/hass

   { set +x; log "restoring PostgreSQL backup for homeassistant"; } 2>/dev/null
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/$HOST::$ARCHIVE var/backup/postgresql/hass.sql.gz --strip-components 3
   sudo chown chris:users ${config.backups.borgDir}/hass.sql.gz
   rsync --progress -avzh ${config.backups.borgDir}/hass.sql.gz $HOST:/tmp
   ssh $HOST 'sudo gunzip -c /tmp/hass.sql.gz > /tmp/hass.sql'
   ssh $HOST 'sudo chown postgres:postgres /tmp/hass.sql'
   ssh $HOST 'sudo mv /tmp/hass.sql /var/lib/postgresql'
   ssh $HOST 'sudo rm -rf /tmp/hass.sql.gz'
   ssh $HOST 'sudo -u postgres psql -U postgres -d template1 -c "DROP DATABASE \"hass\";"'
   ssh $HOST 'sudo -u postgres psql -U postgres -d template1 -c "CREATE DATABASE \"hass\" OWNER \"hass\";"'
   ssh $HOST 'sudo -u postgres psql -U postgres -d hass -f /var/lib/postgresql/hass.sql'
   ssh $HOST 'sudo rm -rf /var/lib/postgresql/hass.sql'
   sudo rm -rf ${config.backups.borgDir}/hass.sql.gz

   { set +x; log "restarting restored homeassistant service on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo systemctl start home-assistant.service'
   '';

in

{

  sops.secrets.borgCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    recoverHomeassistantScript
  ];

}  