{ 
  pkgs,
  config
}:

let
  REPO = "/var/lib/borgbackup/cloud-restore/thinkpad";
  ARCHIVE = "thinkpad-2025.10.10-T02:45:00";
in

pkgs.writeShellScriptBin "recoverEmail" 
''
  cd /
  sudo ${pkgs.borgbackup}/bin/borg extract --verbose --list "${REPO}"::"${ARCHIVE}" /home/chris/email
''