{ 
  pkgs, 
  config 
}:

let
  host = "cypress";
  app = "hass";
  archive = "cypress-2025.01.03-T02:30:13";
  borgRepo = config.backups.borgCypressRepo;
  borgRestoreDir = config.backups.borgRestoreDir;
in

pkgs.writeShellScriptBin "backup-recovery-${app}" 
''
  cd ${borgRestoreDir}
  sudo borg extract --verbose --list ${borgRepo}::${archive} var/lib/${app} --strip-components 2
  sudo chown -R chris:users ${borgRestoreDir}/${app}
  ssh ${host}-tailscale 'sudo systemctl stop home-assistant.service'
  ssh ${host}-tailscale 'sudo rm -rf /var/lib/${app}'
  rsync --progress -avzh ${borgRestoreDir}/${app} ${host}-tailscale:/tmp  
  ssh ${host}-tailscale 'sudo mv /tmp/${app} /var/lib'
  ssh ${host}-tailscale 'sudo chown -R ${app}:${app} /var/lib/${app}'
  sudo rm -rf ${borgRestoreDir}/${app}

  sudo borg extract --verbose --list ${borgRepo}::${archive} var/backup/postgresql/${app}.sql.gz --strip-components 3
  sudo mv ${borgRestoreDir}/${app}.sql.gz /home/chris
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
''