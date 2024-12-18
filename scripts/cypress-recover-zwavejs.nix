{ 
  pkgs, 
  config 
}:

let
  archive = "";
  borgCypressRepo = config.backups.borgCypressRepo;
  borgRestoreDir = config.backups.borgRestoreDir;
in

pkgs.writeShellScriptBin "cypress-recover-zwavejs" 
''
  ssh cypress-tailscale 'sudo systemctl stop docker-zwavejs-root.target'
  ssh cypress-tailscale 'sudo rm -rf /var/lib/docker/volumes/zwavejs'
  
  nixos_old_gen=$(ssh cypress 'readlink -f /run/current-system')
  nixos-rebuild \
  --flake ~/nixos-configs#cypress \
  --target-host cypress \
  --use-remote-sudo \
  --verbose \
  switch
  nixos_new_gen=$(ssh cypress 'readlink -f /run/current-system')
  nvd diff "$nixos_old_gen" "$nixos_new_gen"

  cd ${borgRestoreDir}
  sudo borg extract --verbose --list ${borgCypressRepo}::${archive} var/lib/docker/volumes/zwavejs --strip-components 4
  sudo chown -R chris:users ${borgRestoreDir}/zwavejs
  ssh cypress-tailscale 'sudo systemctl stop docker-zwavejs-root.target'
  ssh cypress-tailscale 'sudo rm -rf /var/lib/docker/volumes/zwavejs'
  rsync --progress -avzh ${borgRestoreDir}/zwavejs cypress-tailscale:/tmp  
  ssh cypress-tailscale 'sudo mv /tmp/zwavejs /var/lib/docker/volumes'
  ssh cypress-tailscale 'sudo chown -R root:root /var/lib/docker/volumes/zwavejs'
  sudo rm -rf ${borgRestoreDir}/zwavejs

  nixos_old_gen=$(ssh cypress 'readlink -f /run/current-system')
  nixos-rebuild \
  --flake ~/nixos-configs#cypress \
  --target-host cypress \
  --use-remote-sudo \
  --verbose \
  switch
  nixos_new_gen=$(ssh cypress 'readlink -f /run/current-system')
  nvd diff "$nixos_old_gen" "$nixos_new_gen"
''