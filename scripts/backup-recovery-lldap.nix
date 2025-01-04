{ 
  pkgs, 
  config 
}:

let
  host = "cypress";
  app = "lldap";
  archive = "cypress-2025.01.04-T02:30:04";
  borgRepo = config.backups.borgCypressRepo;
  borgRestoreDir = config.backups.borgRestoreDir;
in

pkgs.writeShellScriptBin "backup-recovery-${app}" 
''
  # Enable tracing of commands
  set -x

  # Helper function to print styled messages
  log() {
    # Temporarily disable tracing for this function
    { set +x; } 2>/dev/null
    echo -e "\033[1;33m$1\033[0m"
    { set -x; } 2>/dev/null
  }

  # Print starting message
  { set +x; log "Starting backup recovery for ${app} on ${host}"; } 2>/dev/null

  # Step 1: Change directory to borg restore dir
  { set +x; log "Changing directory to ${borgRestoreDir}"; } 2>/dev/null
  cd ${borgRestoreDir}

  # Extract application data
  { set +x; log "Extracting application data for ${app} from borg repository"; } 2>/dev/null
  sudo borg extract --verbose --list ${borgRepo}::${archive} var/lib/private/${app} --strip-components 3

  # Adjust ownership
  { set +x; log "Changing ownership of extracted application data"; } 2>/dev/null
  sudo chown -R chris:users ${borgRestoreDir}/${app}

  # Stop the application service on the remote host
  { set +x; log "Stopping ${app}.service on ${host}-tailscale"; } 2>/dev/null
  ssh ${host}-tailscale 'sudo systemctl stop ${app}.service'

  # Remove existing application data
  { set +x; log "Removing existing application data on ${host}-tailscale"; } 2>/dev/null
  ssh ${host}-tailscale 'sudo rm -rf /var/lib/${app}'
  ssh ${host}-tailscale 'sudo rm -rf /var/lib/private/${app}'

  # Transfer and move restored data
  { set +x; log "Transferring restored data to ${host}-tailscale"; } 2>/dev/null
  rsync --progress -avzh ${borgRestoreDir}/${app} ${host}-tailscale:/tmp
  ssh ${host}-tailscale 'sudo mv /tmp/${app} /var/lib/private'
  ssh ${host}-tailscale 'sudo chown -R ${app}:${app} /var/lib/private/${app}'

  # Cleanup local restore directory
  { set +x; log "Cleaning up local restore directory"; } 2>/dev/null
  sudo rm -rf ${borgRestoreDir}/${app}

  # Restore PostgreSQL backup
  { set +x; log "Restoring PostgreSQL backup for ${app}"; } 2>/dev/null
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

  # Rebuild NixOS configuration
  { set +x; log "Rebuilding NixOS configuration for ${host}"; } 2>/dev/null
  nixos-rebuild \
    --flake ~/nixos-configs#${host} \
    --target-host ${host} \
    --use-remote-sudo \
    --verbose \
    switch
''

#''
#  cd ${borgRestoreDir}
#  sudo borg extract --verbose --list ${borgRepo}::${archive} var/lib/private/${app} --strip-components 3
#  sudo chown -R chris:users ${borgRestoreDir}/${app}
#  ssh ${host}-tailscale 'sudo systemctl stop ${app}.service'
#  ssh ${host}-tailscale 'sudo rm -rf /var/lib/${app}'
#  ssh ${host}-tailscale 'sudo rm -rf /var/lib/private/${app}'
#  rsync --progress -avzh ${borgRestoreDir}/${app} ${host}-tailscale:/tmp  
#  ssh ${host}-tailscale 'sudo mv /tmp/${app} /var/lib/private'
#  ssh ${host}-tailscale 'sudo chown -R ${app}:${app} /var/lib/private/${app}'
#  sudo rm -rf ${borgRestoreDir}/${app}
#
#  sudo borg extract --verbose --list ${borgRepo}::${archive} var/backup/postgresql/${app}.sql.gz --strip-components 3
#  sudo mv ${borgRestoreDir}/${app}.sql.gz /home/chris
#  sudo chown chris:users /home/chris/${app}.sql.gz
#  rsync --progress -avzh /home/chris/${app}.sql.gz ${host}-tailscale:/tmp
#  ssh ${host}-tailscale 'sudo gunzip -c /tmp/${app}.sql.gz > /tmp/${app}.sql'
#  ssh ${host}-tailscale 'sudo chown postgres:postgres /tmp/${app}.sql'
#  ssh ${host}-tailscale 'sudo mv /tmp/${app}.sql /var/lib/postgresql'
#  ssh ${host}-tailscale 'sudo rm -rf /tmp/${app}.sql.gz'
#  ssh ${host}-tailscale 'sudo -u postgres psql -U postgres -d template1 -c "DROP DATABASE \"${app}\";"'
#  ssh ${host}-tailscale 'sudo -u postgres psql -U postgres -d template1 -c "CREATE DATABASE \"${app}\" OWNER \"${app}\";"'
#  ssh ${host}-tailscale 'sudo -u postgres psql -U postgres -d ${app} -f /var/lib/postgresql/${app}.sql'
#  ssh ${host}-tailscale 'sudo rm -rf /var/lib/postgresql/${app}.sql'
#  rm -rf /home/chris/${app}.sql.gz
#
#  nixos-rebuild \
#  --flake ~/nixos-configs#${host} \
#  --target-host ${host} \
#  --use-remote-sudo \
#  --verbose \
#  switch
#''