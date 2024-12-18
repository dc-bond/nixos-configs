{ 
  pkgs, 
  config 
}:

let
  archive = "cypress-2024.12.16-T15:46:03";
  borgCypressRepo = config.backups.borgCypressRepo;
  borgRestoreDir = config.backups.borgRestoreDir;
in

pkgs.writeShellScriptBin "cypress-recover-homeassistant" 
''
  ssh cypress-tailscale 'sudo systemctl stop home-assistant.service'
  ssh cypress-tailscale 'sudo systemctl stop postgresql.service'
  ssh cypress-tailscale 'sudo rm -rf /var/lib/hass'
  ssh cypress-tailscale 'sudo rm -rf /var/lib/postgresql'
  
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
  sudo borg extract --verbose --list ${borgCypressRepo}::${archive} var/lib/hass --strip-components 2
  sudo chown -R chris:users ${borgRestoreDir}/hass
  ssh cypress-tailscale 'sudo systemctl stop home-assistant.service'
  ssh cypress-tailscale 'sudo rm -rf /var/lib/hass'
  rsync --progress -avzh ${borgRestoreDir}/hass cypress-tailscale:/tmp  
  ssh cypress-tailscale 'sudo mv /tmp/hass /var/lib'
  ssh cypress-tailscale 'sudo chown -R hass:hass /var/lib/hass'
  sudo rm -rf ${borgRestoreDir}/hass

  sudo borg extract --verbose --list ${borgCypressRepo}::${archive} var/backup/postgresql/hass.sql.gz --strip-components 3
  sudo mv ${borgRestoreDir}/hass.sql.gz /home/chris
  sudo chown chris:users /home/chris/hass.sql.gz
  rsync --progress -avzh /home/chris/hass.sql.gz cypress-tailscale:/tmp
  ssh cypress-tailscale 'sudo gunzip -c /tmp/hass.sql.gz > /tmp/hass.sql'
  ssh cypress-tailscale 'sudo chown postgres:postgres /tmp/hass.sql'
  ssh cypress-tailscale 'sudo mv /tmp/hass.sql /var/lib/postgresql'
  ssh cypress-tailscale 'sudo rm -rf /tmp/hass.sql.gz'
  ssh cypress-tailscale 'sudo -u postgres psql -U postgres -d template1 -c "DROP DATABASE \"hass\";"'
  ssh cypress-tailscale 'sudo -u postgres psql -U postgres -d template1 -c "CREATE DATABASE \"hass\" OWNER \"hass\";"'
  ssh cypress-tailscale 'sudo -u postgres psql -U postgres -d hass -f /var/lib/postgresql/hass.sql'
  ssh cypress-tailscale 'sudo rm -rf /var/lib/postgresql/hass.sql'
  rm -rf /home/chris/hass.sql.gz

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