{ 
  pkgs, 
  config,
  ...
}:

let

  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";

  recoverMediaServerScript = pkgs.writeShellScriptBin "recoverMediaServer" ''
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

   { set +x; log "starting backup recovery for media server container stack on $HOST"; } 2>/dev/null

   { set +x; log "changing directory to ${config.backups.borgDir}"; } 2>/dev/null
   cd ${config.backups.borgDir}
   
   { set +x; log "extracting application data from borg repository"; } 2>/dev/null
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/$HOST::$ARCHIVE var/lib/docker/volumes/jellyfin --strip-components 4
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/$HOST::$ARCHIVE var/lib/docker/volumes/jellyseerr --strip-components 4
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/$HOST::$ARCHIVE var/lib/docker/volumes/sabnzbd --strip-components 4
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/$HOST::$ARCHIVE var/lib/docker/volumes/prowlarr --strip-components 4
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/$HOST::$ARCHIVE var/lib/docker/volumes/radarr --strip-components 4
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/$HOST::$ARCHIVE var/lib/docker/volumes/sonarr --strip-components 4
   
   { set +x; log "changing ownership of extracted application data"; } 2>/dev/null
   sudo chown -R chris:users ${config.backups.borgDir}/jellyfin
   sudo chown -R chris:users ${config.backups.borgDir}/jellyseerr
   sudo chown -R chris:users ${config.backups.borgDir}/sabnzbd
   sudo chown -R chris:users ${config.backups.borgDir}/prowlarr
   sudo chown -R chris:users ${config.backups.borgDir}/radarr
   sudo chown -R chris:users ${config.backups.borgDir}/sonarr

   { set +x; log "stopping container stack on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo systemctl stop docker-media-server-root.target'

   { set +x; log "removing existing application data on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo rm -rf /var/lib/docker/volumes/jellyfin'
   ssh $HOST 'sudo rm -rf /var/lib/docker/volumes/jellyseerr'
   ssh $HOST 'sudo rm -rf /var/lib/docker/volumes/sabnzbd'
   ssh $HOST 'sudo rm -rf /var/lib/docker/volumes/prowlarr'
   ssh $HOST 'sudo rm -rf /var/lib/docker/volumes/radarr'
   ssh $HOST 'sudo rm -rf /var/lib/docker/volumes/sonarr'

   { set +x; log "transferring restored data to $HOST"; } 2>/dev/null
   rsync --progress -avzh ${config.backups.borgDir}/jellyfin $HOST:/tmp
   rsync --progress -avzh ${config.backups.borgDir}/jellyseerr $HOST:/tmp
   rsync --progress -avzh ${config.backups.borgDir}/sabnzbd $HOST:/tmp
   rsync --progress -avzh ${config.backups.borgDir}/prowlarr $HOST:/tmp
   rsync --progress -avzh ${config.backups.borgDir}/radarr $HOST:/tmp
   rsync --progress -avzh ${config.backups.borgDir}/sonarr $HOST:/tmp
   ssh $HOST 'sudo mv /tmp/jellyfin /var/lib/docker/volumes'
   ssh $HOST 'sudo mv /tmp/jellyseerr /var/lib/docker/volumes'
   ssh $HOST 'sudo mv /tmp/sabnzbd /var/lib/docker/volumes'
   ssh $HOST 'sudo mv /tmp/prowlarr /var/lib/docker/volumes'
   ssh $HOST 'sudo mv /tmp/radarr /var/lib/docker/volumes'
   ssh $HOST 'sudo mv /tmp/sonarr /var/lib/docker/volumes'
   
   { set +x; log "changing ownership of restored application data"; } 2>/dev/null
   ssh $HOST 'sudo chown -R 911:911 /var/lib/docker/volumes/jellyfin'
   ssh $HOST 'sudo chown -R root:root /var/lib/docker/volumes/jellyseerr'
   ssh $HOST 'sudo chown -R root:root /var/lib/docker/volumes/sabnzbd'
   ssh $HOST 'sudo chown -R root:root /var/lib/docker/volumes/prowlarr'
   ssh $HOST 'sudo chown -R root:root /var/lib/docker/volumes/radarr'
   ssh $HOST 'sudo chown -R root:root /var/lib/docker/volumes/sonarr'

   { set +x; log "cleaning up local restore directory"; } 2>/dev/null
   sudo rm -rf ${config.backups.borgDir}/jellyfin
   sudo rm -rf ${config.backups.borgDir}/jellyseerr
   sudo rm -rf ${config.backups.borgDir}/sabnzbd
   sudo rm -rf ${config.backups.borgDir}/prowlarr
   sudo rm -rf ${config.backups.borgDir}/radarr
   sudo rm -rf ${config.backups.borgDir}/sonarr

   { set +x; log "restarting restored media server container stack on $HOST"; } 2>/dev/null
   ssh $HOST 'sudo systemctl start docker-media-server-root.target'
   '';

in

{

  sops.secrets.borgCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    recoverMediaServerScript
  ];

}  