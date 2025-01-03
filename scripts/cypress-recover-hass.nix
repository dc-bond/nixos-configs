{ 
  pkgs, 
  config 
}:

let
  app = "${app}";
  archive = "";
  borgCypressRepo = config.backups.borgCypressRepo;
  borgRestoreDir = config.backups.borgRestoreDir;
in

pkgs.writeShellScriptBin "cypress-recover-${app}" 
''
  ssh cypress-tailscale 'sudo systemctl stop home-assistant.service'
  ssh cypress-tailscale 'sudo systemctl stop postgresql.service'
  ssh cypress-tailscale 'sudo rm -rf /var/lib/${app}'
  ssh cypress-tailscale 'sudo rm -rf /var/lib/postgresql'
  
  nixos-rebuild \
  --flake ~/nixos-configs#cypress \
  --target-host cypress \
  --use-remote-sudo \
  --verbose \
  switch

  cd ${borgRestoreDir}
  sudo borg extract --verbose --list ${borgCypressRepo}::${archive} var/lib/${app} --strip-components 2
  sudo chown -R chris:users ${borgRestoreDir}/${app}
  ssh cypress-tailscale 'sudo systemctl stop home-assistant.service'
  ssh cypress-tailscale 'sudo rm -rf /var/lib/${app}'
  rsync --progress -avzh ${borgRestoreDir}/${app} cypress-tailscale:/tmp  
  ssh cypress-tailscale 'sudo mv /tmp/${app} /var/lib'
  ssh cypress-tailscale 'sudo chown -R ${app}:${app} /var/lib/${app}'
  sudo rm -rf ${borgRestoreDir}/${app}

  sudo borg extract --verbose --list ${borgCypressRepo}::${archive} var/backup/postgresql/${app}.sql.gz --strip-components 3
  sudo mv ${borgRestoreDir}/${app}.sql.gz /home/chris
  sudo chown chris:users /home/chris/${app}.sql.gz
  rsync --progress -avzh /home/chris/${app}.sql.gz cypress-tailscale:/tmp
  ssh cypress-tailscale 'sudo gunzip -c /tmp/${app}.sql.gz > /tmp/${app}.sql'
  ssh cypress-tailscale 'sudo chown postgres:postgres /tmp/${app}.sql'
  ssh cypress-tailscale 'sudo mv /tmp/${app}.sql /var/lib/postgresql'
  ssh cypress-tailscale 'sudo rm -rf /tmp/${app}.sql.gz'
  ssh cypress-tailscale 'sudo -u postgres psql -U postgres -d template1 -c "DROP DATABASE \"${app}\";"'
  ssh cypress-tailscale 'sudo -u postgres psql -U postgres -d template1 -c "CREATE DATABASE \"${app}\" OWNER \"${app}\";"'
  ssh cypress-tailscale 'sudo -u postgres psql -U postgres -d ${app} -f /var/lib/postgresql/${app}.sql'
  ssh cypress-tailscale 'sudo rm -rf /var/lib/postgresql/${app}.sql'
  rm -rf /home/chris/${app}.sql.gz

  nixos-rebuild \
  --flake ~/nixos-configs#cypress \
  --target-host cypress \
  --use-remote-sudo \
  --verbose \
  switch
''