{ 
  pkgs,
  config
}:

let
  REPO = "${config.backups.borgDir}/${config.networking.hostName}";
  ARCHIVE = "thinkpad-2025.10.10-T02:45:00";
in

pkgs.writeShellScriptBin "recoverEmail" 
''
  cd /
  ${pkgs.borgbackup}/bin/borg extract --verbose --list "$REPO"::"$ARCHIVE" ${config.users.users.chris.home}/email
''
  #sudo mkdir /var/lib/borgbackup/cloud-restore
  #sudo cloudRestore