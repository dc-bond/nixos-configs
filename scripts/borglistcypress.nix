{ 
  pkgs, 
  config 
}:

let
  sops.secrets.borgCryptPasswd = {};
in

pkgs.writeShellScriptBin "borglistcypress" ''
  export BORG_PASSPHRASE=$(sops exec-file ${sops.secrets.borgCryptPasswd} 'cat {}')
  sudo borg list ${config.backups.borgCypressRepo} 
''