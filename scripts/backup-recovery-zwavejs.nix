{ 
  pkgs, 
  config 
}:

let
  host = "cypress";
  app = "zwavejs";
  archive = "cypress-2025.01.16-T06:59:25";
  borgRepo = config.backups.borgCypressRepo;
  borgRestoreDir = config.backups.borgRestoreDir;
in

pkgs.writeShellScriptBin "backup-recovery-${app}" 
''
  cd ${borgRestoreDir}
  sudo borg extract --verbose --list ${borgRepo}::${archive} var/lib/docker/volumes/${app} --strip-components 4
  sudo chown -R chris:users ${borgRestoreDir}/${app}
  ssh ${host} 'sudo systemctl stop docker-${app}-root.target'
  ssh ${host} 'sudo rm -rf /var/lib/docker/volumes/${app}'
  rsync --progress -avzh ${borgRestoreDir}/${app} ${host}:/tmp  
  ssh ${host} 'sudo mv /tmp/${app} /var/lib/docker/volumes'
  ssh ${host} 'sudo chown -R root:root /var/lib/docker/volumes/${app}'
  sudo rm -rf ${borgRestoreDir}/${app}

  nixos-rebuild \
  --flake ~/nixos-configs#${host} \
  --target-host ${host} \
  --use-remote-sudo \
  --verbose \
  switch
''