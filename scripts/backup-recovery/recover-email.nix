{ 
  pkgs, 
  config,
  configVars,
  ...
}:

let

  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";

  recoverEmailScript = pkgs.writeShellScriptBin "recoverEmail" ''
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

   { set +x; log "starting backup recovery for email container on aspen"; } 2>/dev/null

   { set +x; log "changing directory to ${config.backups.borgDir}"; } 2>/dev/null
   cd ${config.backups.borgDir}

   { set +x; log "extracting email data from borg repository"; } 2>/dev/null
   sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgDir}/${config.networking.hostName}::$ARCHIVE /home/${configVars.userName}/email --strip-components 2

   { set +x; log "changing ownership of restored application data"; } 2>/dev/null
   sudo chown -R chris:users ${config.backups.borgDir}/email
   '';

in

{

  sops.secrets.borgCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    recoverEmailScript
  ];

}  