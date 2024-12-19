{ 
  pkgs, 
  config 
}:

let
  archive = "cypress-2024.12.19-T02:30:03";
  borgCypressRepo = config.backups.borgCypressRepo;
  borgRestoreDir = config.backups.borgRestoreDir;
in

pkgs.writeShellScriptBin "cypress-recover-zwavejs" 
''
  ssh cypress-tailscale 'sudo systemctl stop docker-zwavejs-root.target'
  ssh cypress-tailscale 'sudo rm -rf /var/lib/docker/volumes/zwavejs'
  
  nixos-rebuild \
  --flake ~/nixos-configs#cypress \
  --target-host cypress \
  --use-remote-sudo \
  --verbose \
  switch

  cd ${borgRestoreDir}
  sudo borg extract --verbose --list ${borgCypressRepo}::${archive} var/lib/docker/volumes/zwavejs --strip-components 4
  sudo chown -R chris:users ${borgRestoreDir}/zwavejs
  ssh cypress-tailscale 'sudo systemctl stop docker-zwavejs-root.target'
  ssh cypress-tailscale 'sudo rm -rf /var/lib/docker/volumes/zwavejs'
  rsync --progress -avzh ${borgRestoreDir}/zwavejs cypress-tailscale:/tmp  
  ssh cypress-tailscale 'sudo mv /tmp/zwavejs /var/lib/docker/volumes'
  ssh cypress-tailscale 'sudo chown -R root:root /var/lib/docker/volumes/zwavejs'
  sudo rm -rf ${borgRestoreDir}/zwavejs

  nixos-rebuild \
  --flake ~/nixos-configs#cypress \
  --target-host cypress \
  --use-remote-sudo \
  --verbose \
  switch
''