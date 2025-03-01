{ 
  pkgs, 
  config,
  ...
}:

let

  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";

  recoverUnifiControllerScript = pkgs.writeShellScriptBin "recoverUnifiController" ''
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

   { set +x; log "starting backup recovery for unifi-controller containers on $HOST"; } 2>/dev/null

   { set +x; log "changing directory to ${config.backups.borgDir}"; } 2>/dev/null
   cd ${config.backups.borgDir}

   { set +x; log "extracting application data from borg repository"; } 2>/dev/null
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/$HOST::$ARCHIVE var/lib/docker/volumes/unifi-controller --strip-components 4
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/$HOST::$ARCHIVE var/lib/docker/volumes/unifi-controller-mongodb-db --strip-components 4
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/$HOST::$ARCHIVE var/lib/docker/volumes/unifi-controller-mongodb-configdb --strip-components 4

   { set +x; log "changing ownership of extracted application data"; } 2>/dev/null
   sudo chown -R chris:users ${config.backups.borgDir}/unifi-controller
   sudo chown -R chris:users ${config.backups.borgDir}/unifi-controller-mongodb-db
   sudo chown -R chris:users ${config.backups.borgDir}/unifi-controller-mongodb-configdb

   { set +x; log "stopping container stack on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo systemctl stop docker-unifi-controller-root.target'
   sleep 20

   { set +x; log "removing existing application data on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo rm -rf /var/lib/docker/volumes/unifi-controller'
   ssh $HOST 'sudo rm -rf /var/lib/docker/volumes/unifi-controller-mongodb-db'
   ssh $HOST 'sudo rm -rf /var/lib/docker/volumes/unifi-controller-mongodb-configdb'

   { set +x; log "transferring restored data to $HOST"; } 2>/dev/null
   rsync --progress -avzh ${config.backups.borgDir}/unifi-controller $HOST:/tmp
   rsync --progress -avzh ${config.backups.borgDir}/unifi-controller-mongodb-db $HOST:/tmp
   rsync --progress -avzh ${config.backups.borgDir}/unifi-controller-mongodb-configdb $HOST:/tmp
   ssh $HOST 'sudo mv /tmp/unifi-controller /var/lib/docker/volumes'
   ssh $HOST 'sudo mv /tmp/unifi-controller-mongodb-db /var/lib/docker/volumes'
   ssh $HOST 'sudo mv /tmp/unifi-controller-mongodb-configdb /var/lib/docker/volumes'

   { set +x; log "changing ownership of restored application data"; } 2>/dev/null
   ssh $HOST 'sudo chown -R root:root /var/lib/docker/volumes/unifi-controller'
   ssh $HOST 'sudo chown root:root /var/lib/docker/volumes/unifi-controller-mongodb-db'
   ssh $HOST 'sudo chown root:root /var/lib/docker/volumes/unifi-controller-mongodb-configdb'
   ssh $HOST 'sudo chown -R nscd:nscd /var/lib/docker/volumes/unifi-controller-mongodb-db/_data'
   ssh $HOST 'sudo chown -R nscd:nscd /var/lib/docker/volumes/unifi-controller-mongodb-configdb/_data'

   { set +x; log "cleaning up local restore directory"; } 2>/dev/null
   sudo rm -rf ${config.backups.borgDir}/unifi-controller
   sudo rm -rf ${config.backups.borgDir}/unifi-controller-mongodb-db
   sudo rm -rf ${config.backups.borgDir}/unifi-controller-mongodo-configdb

   { set +x; log "restarting restored unifi-controller container stack on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo systemctl start docker-unifi-controller-root.target'
   '';

in

{

  sops.secrets.borgCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    recoverUnifiControllerScript
  ];

}  