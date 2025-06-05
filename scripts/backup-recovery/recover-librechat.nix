{ 
  pkgs, 
  config,
  ...
}:

let

  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";

  recoverLibreChatScript = pkgs.writeShellScriptBin "recoverLibreChat" ''
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

   { set +x; log "starting backup recovery for librechat containers on $HOST"; } 2>/dev/null

   { set +x; log "changing directory to ${config.backups.borgCloudDir}"; } 2>/dev/null
   cd ${config.backups.borgCloudDir}

   { set +x; log "extracting application data from borg repository"; } 2>/dev/null
   #sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCloudDir}/$HOST::$ARCHIVE var/lib/docker/volumes/librechat-api-images --strip-components 4
   #sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCloudDir}/$HOST::$ARCHIVE var/lib/docker/volumes/librechat-api-logs --strip-components 4
   #sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCloudDir}/$HOST::$ARCHIVE var/lib/docker/volumes/librechat-api-uploads --strip-components 4
   #sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCloudDir}/$HOST::$ARCHIVE var/lib/docker/volumes/librechat-meilisearch --strip-components 4
   #sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCloudDir}/$HOST::$ARCHIVE var/lib/docker/volumes/librechat-mongodb --strip-components 4
   #sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCloudDir}/$HOST::$ARCHIVE var/lib/docker/volumes/librechat-vectordb --strip-components 4
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCloudDir}/cypress::$ARCHIVE var/lib/docker/volumes/librechat-api-images --strip-components 4
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCloudDir}/cypress::$ARCHIVE var/lib/docker/volumes/librechat-api-logs --strip-components 4
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCloudDir}/cypress::$ARCHIVE var/lib/docker/volumes/librechat-api-uploads --strip-components 4
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCloudDir}/cypress::$ARCHIVE var/lib/docker/volumes/librechat-meilisearch --strip-components 4
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCloudDir}/cypress::$ARCHIVE var/lib/docker/volumes/librechat-mongodb --strip-components 4
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCloudDir}/cypress::$ARCHIVE var/lib/docker/volumes/librechat-vectordb --strip-components 4

   { set +x; log "changing ownership of extracted application data"; } 2>/dev/null
   sudo chown -R chris:users ${config.backups.borgCloudDir}/librechat-api-images
   sudo chown -R chris:users ${config.backups.borgCloudDir}/librechat-api-logs
   sudo chown -R chris:users ${config.backups.borgCloudDir}/librechat-api-uploads
   sudo chown -R chris:users ${config.backups.borgCloudDir}/librechat-meilisearch
   sudo chown -R chris:users ${config.backups.borgCloudDir}/librechat-mongodb
   sudo chown -R chris:users ${config.backups.borgCloudDir}/librechat-vectordb

   { set +x; log "stopping container stack on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo systemctl stop docker-librechat-root.target'
   sleep 20

   { set +x; log "removing existing application data on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo rm -rf /var/lib/docker/volumes/librechat-api-images'
   ssh $HOST 'sudo rm -rf /var/lib/docker/volumes/librechat-api-logs'
   ssh $HOST 'sudo rm -rf /var/lib/docker/volumes/librechat-api-uploads'
   ssh $HOST 'sudo rm -rf /var/lib/docker/volumes/librechat-meilisearch'
   ssh $HOST 'sudo rm -rf /var/lib/docker/volumes/librechat-mongodb'
   ssh $HOST 'sudo rm -rf /var/lib/docker/volumes/librechat-vectordb'

   { set +x; log "transferring restored data to $HOST"; } 2>/dev/null
   rsync --progress -avzh ${config.backups.borgCloudDir}/librechat-api-images $HOST:/tmp
   rsync --progress -avzh ${config.backups.borgCloudDir}/librechat-api-logs $HOST:/tmp
   rsync --progress -avzh ${config.backups.borgCloudDir}/librechat-api-uploads $HOST:/tmp
   rsync --progress -avzh ${config.backups.borgCloudDir}/librechat-meilisearch $HOST:/tmp
   rsync --progress -avzh ${config.backups.borgCloudDir}/librechat-mongodb $HOST:/tmp
   rsync --progress -avzh ${config.backups.borgCloudDir}/librechat-vectordb $HOST:/tmp
   ssh $HOST 'sudo mv /tmp/librechat-api-images /var/lib/docker/volumes'
   ssh $HOST 'sudo mv /tmp/librechat-api-logs /var/lib/docker/volumes'
   ssh $HOST 'sudo mv /tmp/librechat-api-uploads /var/lib/docker/volumes'
   ssh $HOST 'sudo mv /tmp/librechat-meilisearch /var/lib/docker/volumes'
   ssh $HOST 'sudo mv /tmp/librechat-mongodb /var/lib/docker/volumes'
   ssh $HOST 'sudo mv /tmp/librechat-vectordb /var/lib/docker/volumes'

   { set +x; log "changing ownership of restored application data"; } 2>/dev/null
   ssh $HOST 'sudo chown -R root:root /var/lib/docker/volumes/librechat-api-images'
   ssh $HOST 'sudo chown -R root:root /var/lib/docker/volumes/librechat-api-logs'
   ssh $HOST 'sudo chown -R root:root /var/lib/docker/volumes/librechat-api-uploads'
   ssh $HOST 'sudo chown -R root:root /var/lib/docker/volumes/librechat-meilisearch'
   ssh $HOST 'sudo chown root:root /var/lib/docker/volumes/librechat-mongodb'
   ssh $HOST 'sudo chown root:root /var/lib/docker/volumes/librechat-vectordb'
   ssh $HOST 'sudo chown -R nscd:nscd /var/lib/docker/volumes/librechat-mongodb/_data'
   ssh $HOST 'sudo chown -R nscd:nscd /var/lib/docker/volumes/librechat-vectordb/_data'

   { set +x; log "cleaning up local restore directory"; } 2>/dev/null
   sudo rm -rf ${config.backups.borgCloudDir}/librechat-api-images
   sudo rm -rf ${config.backups.borgCloudDir}/librechat-api-logs
   sudo rm -rf ${config.backups.borgCloudDir}/librechat-api-uploads
   sudo rm -rf ${config.backups.borgCloudDir}/librechat-meilisearch
   sudo rm -rf ${config.backups.borgCloudDir}/librechat-mongodb
   sudo rm -rf ${config.backups.borgCloudDir}/librechat-vectordb

   { set +x; log "restarting restored librechat container stack on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo systemctl start docker-librechat-root.target'
   '';

in

{

  sops.secrets.borgCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    recoverLibreChatScript
  ];

}  