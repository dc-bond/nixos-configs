{ 
  pkgs, 
  config,
  ...
}:

let

  borgCypressCryptPasswdFile = "/run/secrets/borgCypressCryptPasswd";

  listCypressArchivesScript = pkgs.writeShellScriptBin "listCypressArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
    sudo -E ${pkgs.borgbackup}/bin/borg list ${config.backups.borgCypressRepo} 
    '';

  infoCypressArchivesScript = pkgs.writeShellScriptBin "infoCypressArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
    sudo -E ${pkgs.borgbackup}/bin/borg info ${config.backups.borgCypressRepo} 
    '';

in

{

  sops.secrets.borgCypressCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    listCypressArchivesScript
    infoCypressArchivesScript
  ];

}  

#recoverCypressHassScript = pkgs.writeShellScriptBin "recoverCypressHass" ''
#    #!/bin/bash
#
#    set -e
#    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
#
#    read -p "Enter hostname to recover: " HOST
#    if [ -z "$HOST" ]; then
#      echo "Error: host required."
#      exit 1
#    fi
#    
#    read -p "Enter the archive to recover: " ARCHIVE
#    if [ -z "$ARCHIVE" ]; then
#      echo "Error: archive required."
#      exit 1
#    fi
#
#    read -p "Enter the application to recover: " APP
#    if [ -z "$APP" ]; then
#      echo "Error: application required."
#      exit 1
#    fi
#
#    cd ${config.backups.borgRestoreDir}
#    sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCypressRepo}::$ARCHIVE var/lib/$APP --strip-components 2
#    sudo chown -R chris:users ${config.backups.borgRestoreDir}/$APP
#    ssh $HOST-tailscale 'sudo systemctl stop home-assistant.service'
#    ssh $HOST-tailscale 'sudo rm -rf /var/lib/$APP'
#    rsync --progress -avzh ${config.backups.borgRestoreDir}/$APP $HOST-tailscale:/tmp  
#    ssh $HOST-tailscale 'sudo mv /tmp/$APP /var/lib'
#    ssh $HOST-tailscale 'sudo chown -R $APP:$APP /var/lib/$APP'
#    sudo rm -rf ${config.backups.borgRestoreDir}/$APP
#  
#    sudo -E ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCypressRepo}::$ARCHIVE var/backup/postgresql/$APP.sql.gz --strip-components 3
#    sudo mv ${config.backups.borgRestoreDir}/$APP.sql.gz /home/chris
#    sudo chown chris:users /home/chris/$APP.sql.gz
#    rsync --progress -avzh /home/chris/$APP.sql.gz $HOST-tailscale:/tmp
#    ssh $HOST-tailscale 'sudo gunzip -c /tmp/$APP.sql.gz > /tmp/$APP.sql'
#    ssh $HOST-tailscale 'sudo chown postgres:postgres /tmp/$APP.sql'
#    ssh $HOST-tailscale 'sudo mv /tmp/$APP.sql /var/lib/postgresql'
#    ssh $HOST-tailscale 'sudo rm -rf /tmp/$APP.sql.gz'
#    ssh $HOST-tailscale 'sudo -u postgres psql -U postgres -d template1 -c "DROP DATABASE \"$APP\";"'
#    ssh $HOST-tailscale 'sudo -u postgres psql -U postgres -d template1 -c "CREATE DATABASE \"$APP\" OWNER \"$APP\";"'
#    ssh $HOST-tailscale 'sudo -u postgres psql -U postgres -d $APP -f /var/lib/postgresql/$APP.sql'
#    ssh $HOST-tailscale 'sudo rm -rf /var/lib/postgresql/$APP.sql'
#    rm -rf /home/chris/$APP.sql.gz
#  
#    nixos-rebuild \
#    --flake ~/nixos-configs#$HOST \
#    --target-host $HOST \
#    --use-remote-sudo \
#    --verbose \
#    switch
#    '';
#