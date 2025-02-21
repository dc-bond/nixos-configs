{ 
  pkgs, 
  config,
  ...
}:

let

  borgCypressCryptPasswdFile = "/run/secrets/borgCypressCryptPasswd";

  listCypressArchivesScript = pkgs.writeShellScriptBin "listCypressArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    sudo -E ${pkgs.borgbackup}/bin/borg list ${config.backups.borgDir}/cypress
    '';

  infoCypressArchivesScript = pkgs.writeShellScriptBin "infoCypressArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCypressCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    sudo -E ${pkgs.borgbackup}/bin/borg info ${config.backups.borgDir}/cypress
    '';

in

{

  sops.secrets.borgCypressCryptPasswd = {};

  environment.systemPackages = with pkgs; [ 
    listCypressArchivesScript
    infoCypressArchivesScript
  ];

}  