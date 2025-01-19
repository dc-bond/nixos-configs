{ 
  pkgs, 
  config 
}:

let
  listCypressArchivesScript = pkgs.writeShellScriptBin "cypressArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(cat ${sops.secrets.borgCryptPasswd.path})
    sudo borg list ${config.backups.borgCypressRepo} 
    '';
in

{

  sops.secrets.borgCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    listCypressArchivesScript
  ];

}