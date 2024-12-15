{ 
  pkgs, 
  config 
}:

let
  archive = "cypress-2024.12.15-T15:52:17";
  app = "hass";
  borgCypressRepo = config.backups.borgCypressRepo;
  borgRestoreDir = config.backups.borgRestoreDir;
in

pkgs.writeShellScriptBin "borg-restore" 
#''
#  cd ${borgRestoreDir}
#  sudo borg extract --verbose --list ${borgCypressRepo}::${archive} var/lib/${app} --strip-components 2
#  sudo borg extract --verbose --list ${borgCypressRepo}::${archive} var/backup/postgres/homeassistant.sql.gz --strip-components 3
#  sudo chown -R chris:users ${app}
#  ssh cypress-tailscale 'sudo systemctl stop home-assistant.service'
#  ssh cypress-tailscale 'sudo rm -rf /var/lib/${app}'
#  rsync --progress -avzh ${app} cypress-tailscale:/tmp  
#  ssh cypress-tailscale 'sudo mv /tmp/${app} /var/lib'
#  ssh cypress-tailscale 'sudo chown -R ${app}:${app} /var/lib/${app}'
#  sudo rm -rf ${app}
#  
#  nixos_old_gen=$(ssh cypress 'readlink -f /run/current-system')
#  nixos-rebuild \
#  --flake ~/nixos-configs#cypress \
#  --target-host cypress \
#  --use-remote-sudo \
#  --verbose \
#  switch
#  nixos_new_gen=$(ssh cypress 'readlink -f /run/current-system')
#  nvd diff "$nixos_old_gen" "$nixos_new_gen"
#''

''
  cd ${borgRestoreDir}
  sudo borg extract --verbose --list ${borgCypressRepo}::${archive} var/backup/postgresql/homeassistant.sql.gz --strip-components 3
''