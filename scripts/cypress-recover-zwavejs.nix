{ 
  pkgs, 
  config 
}:

let
  app = "zwavejs";
  archive = "";
  borgCypressRepo = config.backups.borgCypressRepo;
  borgRestoreDir = config.backups.borgRestoreDir;
in

pkgs.writeShellScriptBin "cypress-recover-${app}" 
''
  ssh cypress-tailscale 'sudo systemctl stop docker-${app}-root.target'
  ssh cypress-tailscale 'sudo rm -rf /var/lib/docker/volumes/${app}'
  
  nixos-rebuild \
  --flake ~/nixos-configs#cypress \
  --target-host cypress \
  --use-remote-sudo \
  --verbose \
  switch

  cd ${borgRestoreDir}
  sudo borg extract --verbose --list ${borgCypressRepo}::${archive} var/lib/docker/volumes/${app} --strip-components 4
  sudo chown -R chris:users ${borgRestoreDir}/${app}
  ssh cypress-tailscale 'sudo systemctl stop docker-${app}-root.target'
  ssh cypress-tailscale 'sudo rm -rf /var/lib/docker/volumes/${app}'
  rsync --progress -avzh ${borgRestoreDir}/${app} cypress-tailscale:/tmp  
  ssh cypress-tailscale 'sudo mv /tmp/${app} /var/lib/docker/volumes'
  ssh cypress-tailscale 'sudo chown -R root:root /var/lib/docker/volumes/${app}'
  sudo rm -rf ${borgRestoreDir}/${app}

  nixos-rebuild \
  --flake ~/nixos-configs#cypress \
  --target-host cypress \
  --use-remote-sudo \
  --verbose \
  switch
''