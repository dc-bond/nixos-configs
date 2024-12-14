{ 
  pkgs, 
  config 
}:

let
  repo = /var/lib/borg-backups/cypress;
  archive = cypress-2024.12.13-T02:30:01;
  restoreDir = /var/lib/restore;
  borgCypressCryptPasswd = config.sops.secrets.borgCypressCryptPasswd.path;
in

pkgs.writeShellScriptBin "borg-restore" 
''
export BORG_PASSPHRASE='$(cat ${borgCypressCryptPasswd})'
RESTOREDIR=/home/xixor/hdd1/borg-restore-$ARCHIVE
mkdir ${restoreDir}
cd ${restoreDir}
borg extract --verbose --list ${repo}::${archive} var/lib/hass --strip-components 2
''