{ 
  pkgs, 
  config 
}:

let
  host = "cypress";
  app = "authelia-opticon";
  archive = "";
  borgRepo = config.backups.borgCypressRepo;
  borgRestoreDir = config.backups.borgRestoreDir;
in

pkgs.writeShellScriptBin "backup-recovery-${app}" 
''
  cd ${borgRestoreDir}
  sudo borg extract --verbose --list ${borgRepo}::${archive} var/lib/${app} --strip-components 2
  sudo chown -R chris:users ${borgRestoreDir}/${app}
  sudo borg extract --verbose --list ${borgRepo}::${archive} var/lib/redis-${app} --strip-components 2
  sudo chown -R chris:users ${borgRestoreDir}/redis-${app}
  ssh ${host}-tailscale 'sudo systemctl stop ${app}.service'
  ssh ${host}-tailscale 'sudo systemctl stop redis-${app}.service'
  ssh ${host}-tailscale 'sudo rm -rf /var/lib/${app}'
  ssh ${host}-tailscale 'sudo rm -rf /var/lib/redis-${app}'
  rsync --progress -avzh ${borgRestoreDir}/${app} ${host}-tailscale:/tmp  
  rsync --progress -avzh ${borgRestoreDir}/redis-${app} ${host}-tailscale:/tmp  
  ssh ${host}-tailscale 'sudo mv /tmp/${app} /var/lib'
  ssh ${host}-tailscale 'sudo mv /tmp/redis-${app} /var/lib'
  ssh ${host}-tailscale 'sudo chown -R ${app}:${app} /var/lib/${app}'
  ssh ${host}-tailscale 'sudo chown -R ${app}:${app} /var/lib/redis-${app}'
  sudo rm -rf ${borgRestoreDir}/${app}
  sudo rm -rf ${borgRestoreDir}/redis-${app}

  nixos-rebuild \
  --flake ~/nixos-configs#${host} \
  --target-host ${host} \
  --use-remote-sudo \
  --verbose \
  switch
''