{ 
  pkgs, 
  config 
}:

let
  archive = "cypress-2024.12.13-T02:30:01";
  app = "hass";
  #borgCypressCryptPasswd = config.sops.secrets.borgCypressCryptPasswd.path;
  borgCypressRepo = config.backups.borgCypressRepo;
  borgRestoreDir = config.backups.borgRestoreDir;
in

pkgs.writeShellScriptBin "borg-restore" 
''
  cd ${borgRestoreDir}
  sudo borg extract --verbose --list ${borgCypressRepo}::${archive} var/lib/${app} --strip-components 2
  sudo chown -R chris:users ${app}
  ssh cypress-tailscale 'sudo systemctl stop home-assistant.service'
  ssh cypress-tailscale 'sudo rm -rf /var/lib/${app}'
  rsync --progress -avhe ssh ${app} chris@cypress-tailscale:/tmp
  ssh cypress-tailscale 'sudo mv /tmp/${app} /var/lib'
  ssh cypress-tailscale 'sudo chown -R ${app}:${app} /var/lib/${app}'
  sudo rm -rf ${app}
  
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
#export BORG_PASSPHRASE='$(cat ${borgCypressCryptPasswd})'