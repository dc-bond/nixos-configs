{ 
  pkgs, 
  config,
  ...
}:

let

  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";

  recoverLldapScript = pkgs.writeShellScriptBin "recoverLldap" ''
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

   { set +x; log "starting backup recovery for lldap on $HOST"; } 2>/dev/null

   { set +x; log "changing directory to ${config.backups.borgDir}"; } 2>/dev/null
   cd ${config.backups.borgDir}

   { set +x; log "extracting application data from borg repository"; } 2>/dev/null
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/$HOST::$ARCHIVE var/lib/private/lldap --strip-components 3

   { set +x; log "changing ownership of extracted application data"; } 2>/dev/null
   sudo chown -R chris:users ${config.backups.borgDir}/lldap

   { set +x; log "stopping lldap.service on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo systemctl stop lldap.service'

   { set +x; log "removing existing application data on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo rm -rf /var/lib/lldap'
   ssh $HOST 'sudo rm -rf /var/lib/private/lldap'

   { set +x; log "transferring restored data to $HOST"; } 2>/dev/null
   rsync --progress -avzh ${config.backups.borgDir}/lldap $HOST:/tmp
   ssh $HOST 'sudo mv /tmp/lldap /var/lib/private'

   { set +x; log "cleaning up local restore directory"; } 2>/dev/null
   sudo rm -rf ${config.backups.borgDir}/lldap

   { set +x; log "restoring PostgreSQL backup for lldap"; } 2>/dev/null
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/$HOST::$ARCHIVE var/backup/postgresql/lldap.sql.gz --strip-components 3
   sudo chown chris:users ${config.backups.borgDir}/lldap.sql.gz
   rsync --progress -avzh ${config.backups.borgDir}/lldap.sql.gz $HOST:/tmp
   ssh $HOST 'sudo gunzip -c /tmp/lldap.sql.gz > /tmp/lldap.sql'
   ssh $HOST 'sudo chown postgres:postgres /tmp/lldap.sql'
   ssh $HOST 'sudo mv /tmp/lldap.sql /var/lib/postgresql'
   ssh $HOST 'sudo rm -rf /tmp/lldap.sql.gz'
   ssh $HOST 'sudo -u postgres psql -U postgres -d template1 -c "DROP DATABASE \"lldap\";"'
   ssh $HOST 'sudo -u postgres psql -U postgres -d template1 -c "CREATE DATABASE \"lldap\" OWNER \"lldap\";"'
   ssh $HOST 'sudo -u postgres psql -U postgres -d lldap -f /var/lib/postgresql/lldap.sql'
   ssh $HOST 'sudo rm -rf /var/lib/postgresql/lldap.sql'
   sudo rm -rf ${config.backups.borgDir}/lldap.sql.gz

   { set +x; log "restarting restored lldap service on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo systemctl start lldap.service'
   '';

in

{

  sops.secrets.borgCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    recoverLldapScript
  ];

}  