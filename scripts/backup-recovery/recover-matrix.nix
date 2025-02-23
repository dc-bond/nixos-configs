{ 
  pkgs, 
  config,
  ...
}:

let

  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";

  recoverMatrixScript = pkgs.writeShellScriptBin "recoverMatrix" ''
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

   { set +x; log "starting backup recovery for matrix on $HOST"; } 2>/dev/null

   { set +x; log "changing directory to ${config.backups.borgDir}"; } 2>/dev/null
   cd ${config.backups.borgDir}

   { set +x; log "extracting application data from borg repository"; } 2>/dev/null
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/$HOST::$ARCHIVE var/lib/matrix-synapse --strip-components 2
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/$HOST::$ARCHIVE var/lib/redis-matrix-synapse --strip-components 2

   { set +x; log "changing ownership of extracted application data"; } 2>/dev/null
   sudo chown -R chris:users ${config.backups.borgDir}/matrix-synapse
   sudo chown -R chris:users ${config.backups.borgDir}/redis-matrix-synapse

   { set +x; log "stopping matrix-synapse stack on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo systemctl stop matrix-synapse.service'
   ssh $HOST 'sudo systemctl stop redis-matrix-synapse.service'

   { set +x; log "removing existing application data on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo rm -rf /var/lib/matrix-synapse'
   ssh $HOST 'sudo rm -rf /var/lib/redis-matrix-synapse'

   { set +x; log "transferring restored data to $HOST"; } 2>/dev/null
   rsync --progress -avzh ${config.backups.borgDir}/matrix-synapse $HOST:/tmp
   rsync --progress -avzh ${config.backups.borgDir}/redis-matrix-synapse $HOST:/tmp
   ssh $HOST 'sudo mv /tmp/matrix-synapse /var/lib'
   ssh $HOST 'sudo mv /tmp/redis-matrix-synapse /var/lib'

   { set +x; log "changing ownership of restored application data"; } 2>/dev/null
   ssh $HOST 'sudo chown -R matrix-synapse:matrix-synapse /var/lib/matrix-synapse'
   ssh $HOST 'sudo chown -R matrix-synapse:matrix-synapse /var/lib/redis-matrix-synapse'

   { set +x; log "cleaning up local restore directory"; } 2>/dev/null
   sudo rm -rf ${config.backups.borgDir}/matrix-synapse
   sudo rm -rf ${config.backups.borgDir}/redis-matrix-synapse

   { set +x; log "restoring PostgreSQL backup for matrix-synapse"; } 2>/dev/null
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/$HOST::$ARCHIVE var/backup/postgresql/matrix-synapse.sql.gz --strip-components 3
   sudo chown chris:users ${config.backups.borgDir}/matrix-synapse.sql.gz
   rsync --progress -avzh ${config.backups.borgDir}/matrix-synapse.sql.gz $HOST:/tmp
   ssh $HOST 'sudo gunzip -c /tmp/matrix-synapse.sql.gz > /tmp/matrix-synapse.sql'
   ssh $HOST 'sudo chown postgres:postgres /tmp/matrix-synapse.sql'
   ssh $HOST 'sudo mv /tmp/matrix-synapse.sql /var/lib/postgresql'
   ssh $HOST 'sudo rm -rf /tmp/matrix-synapse.sql.gz'
   ssh $HOST 'sudo -u postgres psql -U postgres -d template1 -c "DROP DATABASE \"matrix-synapse\";"'
   ssh $HOST 'sudo -u postgres psql -U postgres -d template1 -c "CREATE DATABASE \"matrix-synapse\" ENCODING \"UTF8\" LC_COLLATE \"C\" LC_CTYPE \"C\" TEMPLATE \"template0\" OWNER \"matrix-synapse\";"'
   ssh $HOST 'sudo -u postgres psql -U postgres -d matrix-synapse -f /var/lib/postgresql/matrix-synapse.sql'
   ssh $HOST 'sudo rm -rf /var/lib/postgresql/matrix-synapse.sql'
   sudo rm -rf ${config.backups.borgDir}/matrix-synapse.sql.gz

   { set +x; log "restarting restored matrix-synapse service on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo systemctl start redis-matrix-synapse.service'
   sleep 5 
   ssh $HOST 'sudo systemctl start matrix-synapse.service'
   '';

in

{

  sops.secrets.borgCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    recoverMatrixScript
  ];

}  