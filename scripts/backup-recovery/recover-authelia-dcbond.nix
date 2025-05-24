{ 
  pkgs, 
  config,
  ...
}:

let

  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";

  recoverAutheliaDcbondScript = pkgs.writeShellScriptBin "recoverAutheliaDcbond" ''
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

   { set +x; log "starting backup recovery for authelia-dcbond on $HOST"; } 2>/dev/null

   { set +x; log "changing directory to ${config.backups.borgCloudDir}"; } 2>/dev/null
   cd ${config.backups.borgCloudDir}

   { set +x; log "extracting application data from borg repository"; } 2>/dev/null
   #sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCloudDir}/$HOST::$ARCHIVE var/lib/authelia-dcbond --strip-components 2
   #sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCloudDir}/$HOST::$ARCHIVE var/lib/redis-authelia-dcbond --strip-components 2
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCloudDir}/cypress::$ARCHIVE var/lib/authelia-dcbond --strip-components 2
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCloudDir}/cypress::$ARCHIVE var/lib/redis-authelia-dcbond --strip-components 2

   { set +x; log "changing ownership of extracted application data"; } 2>/dev/null
   sudo chown -R chris:users ${config.backups.borgCloudDir}/authelia-dcbond
   sudo chown -R chris:users ${config.backups.borgCloudDir}/redis-authelia-dcbond

   { set +x; log "stopping authelia-dcbond stack on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo systemctl stop authelia-dcbond.service'
   ssh $HOST 'sudo systemctl stop redis-authelia-dcbond.service'

   { set +x; log "removing existing application data on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo rm -rf /var/lib/authelia-dcbond'
   ssh $HOST 'sudo rm -rf /var/lib/redis-authelia-dcbond'

   { set +x; log "transferring restored data to $HOST"; } 2>/dev/null
   rsync --progress -avzh ${config.backups.borgCloudDir}/authelia-dcbond $HOST:/tmp
   rsync --progress -avzh ${config.backups.borgCloudDir}/redis-authelia-dcbond $HOST:/tmp
   ssh $HOST 'sudo mv /tmp/authelia-dcbond /var/lib'
   ssh $HOST 'sudo mv /tmp/redis-authelia-dcbond /var/lib'

   { set +x; log "changing ownership of restored application data"; } 2>/dev/null
   ssh $HOST 'sudo chown -R authelia-dcbond:authelia-dcbond /var/lib/authelia-dcbond'
   ssh $HOST 'sudo chown -R authelia-dcbond:authelia-dcbond /var/lib/redis-authelia-dcbond'

   { set +x; log "cleaning up local restore directory"; } 2>/dev/null
   sudo rm -rf ${config.backups.borgCloudDir}/authelia-dcbond
   sudo rm -rf ${config.backups.borgCloudDir}/redis-authelia-dcbond

   { set +x; log "restarting restored authelia-dcbond service on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo systemctl start redis-authelia-dcbond.service'
   sleep 5 
   ssh $HOST 'sudo systemctl start authelia-dcbond.service'
   '';

in

{

  sops.secrets.borgCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    recoverAutheliaDcbondScript
  ];

}  