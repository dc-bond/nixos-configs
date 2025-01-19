{ 
  pkgs, 
  config,
  ...
}:

let
  host = "cypress";
  app = "hass";
  archive = "cypress-2025.01.19-T02:30:01";
  borgCypressCryptPasswdFile = "/run/secrets/borgCypressCryptPasswd";
  recoverCypressHassScript = pkgs.writeShellScriptBin "recoverCypressHass" ''
    #!/bin/bash

    set -e
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})

    cd ${config.backups.borgRestoreDir}
    sudo ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCypressRepo}::${archive} var/lib/${app} --strip-components 2
    sudo chown -R chris:users ${config.backups.borgRestoreDir}/${app}
    ssh ${host}-tailscale 'sudo systemctl stop home-assistant.service'
    ssh ${host}-tailscale 'sudo rm -rf /var/lib/${app}'
    rsync --progress -avzh ${config.backups.borgRestoreDir}/${app} ${host}-tailscale:/tmp  
    ssh ${host}-tailscale 'sudo mv /tmp/${app} /var/lib'
    ssh ${host}-tailscale 'sudo chown -R ${app}:${app} /var/lib/${app}'
    sudo rm -rf ${config.backups.borgRestoreDir}/${app}
  
    sudo ${pkgs.borgbackup}/bin/borg extract --verbose --list ${config.backups.borgCypressRepo}::${archive} var/backup/postgresql/${app}.sql.gz --strip-components 3
    sudo mv ${config.backups.borgRestoreDir}/${app}.sql.gz /home/chris
    sudo chown chris:users /home/chris/${app}.sql.gz
    rsync --progress -avzh /home/chris/${app}.sql.gz ${host}-tailscale:/tmp
    ssh ${host}-tailscale 'sudo gunzip -c /tmp/${app}.sql.gz > /tmp/${app}.sql'
    ssh ${host}-tailscale 'sudo chown postgres:postgres /tmp/${app}.sql'
    ssh ${host}-tailscale 'sudo mv /tmp/${app}.sql /var/lib/postgresql'
    ssh ${host}-tailscale 'sudo rm -rf /tmp/${app}.sql.gz'
    ssh ${host}-tailscale 'sudo -u postgres psql -U postgres -d template1 -c "DROP DATABASE \"${app}\";"'
    ssh ${host}-tailscale 'sudo -u postgres psql -U postgres -d template1 -c "CREATE DATABASE \"${app}\" OWNER \"${app}\";"'
    ssh ${host}-tailscale 'sudo -u postgres psql -U postgres -d ${app} -f /var/lib/postgresql/${app}.sql'
    ssh ${host}-tailscale 'sudo rm -rf /var/lib/postgresql/${app}.sql'
    rm -rf /home/chris/${app}.sql.gz
  
    nixos-rebuild \
    --flake ~/nixos-configs#${host} \
    --target-host ${host} \
    --use-remote-sudo \
    --verbose \
    switch
    '';
in

{

  sops.secrets.borgCypressCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    recoverCypressHassScript
  ];

}