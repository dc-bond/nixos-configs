{ 
  pkgs, 
  config,
  ...
}:

let

  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";

  recoverPhotoprismScript = pkgs.writeShellScriptBin "recoverPhotoprism" ''
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
   HOSTS=("aspen" "cypress" "thinkpad")
   
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

   { set +x; log "starting backup recovery for lldap on $HOST"; } 2>/dev/null

   { set +x; log "changing directory to ${config.backups.borgCloudDir}"; } 2>/dev/null
   cd ${config.backups.borgCloudDir}

   { set +x; log "extracting application data from borg repository"; } 2>/dev/null
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCloudDir}/$HOST::$ARCHIVE var/lib/private/photoprism --strip-components 3

   { set +x; log "changing ownership of extracted application data"; } 2>/dev/null
   sudo chown -R chris:users ${config.backups.borgCloudDir}/photoprism

   { set +x; log "stopping lldap.service on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo systemctl stop photoprism.service'

   { set +x; log "removing existing application data on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo rm -rf /var/lib/photoprism'
   ssh $HOST 'sudo rm -rf /var/lib/private/photoprism'

   { set +x; log "transferring restored data to $HOST"; } 2>/dev/null
   rsync --progress -avzh ${config.backups.borgCloudDir}/photoprism $HOST:/tmp
   ssh $HOST 'sudo mv /tmp/photoprism /var/lib/private'

   { set +x; log "cleaning up local restore directory"; } 2>/dev/null
   sudo rm -rf ${config.backups.borgCloudDir}/photoprism

   { set +x; log "restoring MySQL backup for photoprism"; } 2>/dev/null
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCloudDir}/$HOST::$ARCHIVE var/backup/mysql/photoprism.gz --strip-components 3
   sudo chown chris:users ${config.backups.borgCloudDir}/photoprism.gz
   rsync --progress -avzh ${config.backups.borgCloudDir}/photoprism.gz $HOST:/tmp
   ssh $HOST 'sudo gunzip -c /tmp/photoprism.gz > /tmp/photoprism.sql'
   ssh $HOST 'sudo chown mysql:mysql /tmp/photoprism.sql'
   ssh $HOST 'sudo -u mysql mysql -e "DROP DATABASE IF EXISTS photoprism;"'
   ssh $HOST 'sudo -u mysql mysql -e "CREATE DATABASE photoprism;"'
   ssh $HOST 'sudo -u mysql mysql -e "GRANT ALL PRIVILEGES ON photoprism.* TO \"photoprism\"@\"localhost\";"'
   ssh $HOST 'sudo -u mysql mysql photoprism < /tmp/photoprism.sql'
   ssh $HOST 'sudo rm -rf /tmp/photoprism.gz'
   ssh $HOST 'sudo rm -rf /tmp/photoprism.sql'
   sudo rm -rf ${config.backups.borgCloudDir}/photoprism.gz

   { set +x; log "restarting restored photoprism service on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo systemctl start photoprism.service'
   '';

in

{

  sops.secrets.borgCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    recoverPhotoprismScript
  ];

}  