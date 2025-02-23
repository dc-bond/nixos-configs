{ 
  pkgs, 
  config,
  ...
}:

let

  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";

  listArchivesScript = pkgs.writeShellScriptBin "listArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    sudo -E ${pkgs.borgbackup}/bin/borg list ${config.backups.borgDir}/${config.networking.hostName}
    '';

  infoArchivesScript = pkgs.writeShellScriptBin "infoArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    sudo -E ${pkgs.borgbackup}/bin/borg info ${config.backups.borgDir}/${config.networking.hostName}
    '';

in

{

  sops.secrets.borgCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    listArchivesScript
    infoArchivesScript
  ];

}  