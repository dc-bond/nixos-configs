{ 
  pkgs, 
  config,
  ...
}:

let

  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";

  recoverNextcloudScript = pkgs.writeShellScriptBin "recoverNextcloud" ''
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

   { set +x; log "starting backup recovery for nextcloud on $HOST"; } 2>/dev/null

   { set +x; log "changing directory to ${config.backups.borgDir}"; } 2>/dev/null
   cd ${config.backups.borgDir}

   { set +x; log "extracting application data for nextcloud from borg repository"; } 2>/dev/null
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/$HOST::$ARCHIVE var/lib/nextcloud --strip-components 2
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/$HOST::$ARCHIVE var/lib/redis-nextcloud --strip-components 2

   { set +x; log "changing ownership of extracted application data"; } 2>/dev/null
   sudo chown -R chris:users ${config.backups.borgDir}/nextcloud
   sudo chown -R chris:users ${config.backups.borgDir}/redis-nextcloud

   { set +x; log "stopping nextcloud stack on $HOST"; } 2>/dev/null
   ssh $HOST 'nextcloud-occ maintenance:mode --on'
   ssh $HOST 'sudo systemctl stop redis-nextcloud.service'

   { set +x; log "removing existing application data on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo rm -rf /var/lib/nextcloud'
   ssh $HOST 'sudo rm -rf /var/lib/redis-nextcloud'

   { set +x; log "transferring restored data to $HOST"; } 2>/dev/null
   rsync --progress -avzh ${config.backups.borgDir}/nextcloud $HOST:/tmp
   rsync --progress -avzh ${config.backups.borgDir}/redis-nextcloud $HOST:/tmp
   ssh $HOST 'sudo mv /tmp/nextcloud /var/lib'
   ssh $HOST 'sudo mv /tmp/redis-nextcloud /var/lib'

   { set +x; log "changing ownership of restored application data"; } 2>/dev/null
   ssh $HOST 'sudo chown -R nextcloud:nextcloud /var/lib/nextcloud'
   ssh $HOST 'sudo chown -R nextcloud:nextcloud /var/lib/redis-nextcloud'

   { set +x; log "cleaning up local restore directory"; } 2>/dev/null
   sudo rm -rf ${config.backups.borgDir}/nextcloud
   sudo rm -rf ${config.backups.borgDir}/redis-nextcloud

   { set +x; log "restoring PostgreSQL backup for nextcloud"; } 2>/dev/null
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/$HOST::$ARCHIVE var/backup/postgresql/nextcloud.sql.gz --strip-components 3
   sudo chown chris:users ${config.backups.borgDir}/nextcloud.sql.gz
   rsync --progress -avzh ${config.backups.borgDir}/nextcloud.sql.gz $HOST:/tmp
   ssh $HOST 'sudo gunzip -c /tmp/nextcloud.sql.gz > /tmp/nextcloud.sql'
   ssh $HOST 'sudo chown postgres:postgres /tmp/nextcloud.sql'
   ssh $HOST 'sudo mv /tmp/nextcloud.sql /var/lib/postgresql'
   ssh $HOST 'sudo rm -rf /tmp/nextcloud.sql.gz'
   ssh $HOST 'sudo -u postgres psql -U postgres -d template1 -c "DROP DATABASE \"nextcloud\";"'
   ssh $HOST 'sudo -u postgres psql -U postgres -d template1 -c "CREATE DATABASE \"nextcloud\" OWNER \"nextcloud\";"'
   ssh $HOST 'sudo -u postgres psql -U postgres -d nextcloud -f /var/lib/postgresql/nextcloud.sql'
   ssh $HOST 'sudo rm -rf /var/lib/postgresql/nextcloud.sql'
   sudo rm -rf ${config.backups.borgDir}/nextcloud.sql.gz

   { set +x; log "restarting restored nextcloud service on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo systemctl start redis-nextcloud.service'
   sleep 5 
   ssh $HOST 'nextcloud-occ maintenance:mode --off'
   '';

in

{

  sops.secrets.borgCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    recoverNextcloudScript
  ];

}  