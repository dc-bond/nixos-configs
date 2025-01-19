{ 
  pkgs, 
  config,
  ...
}:

let
  borgCypressCryptPasswdFile = "/run/secrets/borgCypressCryptPasswd";
  borgCypressArchivesListScript = pkgs.writeShellScriptBin "borgCypressArchivesList" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(cat ${borgCypressCryptPasswdFile})
    ${pkgs.borgbackup}/bin/borg list ${config.backups.borgCypressRepo} 
    '';
  borgCypressArchivesInfoScript = pkgs.writeShellScriptBin "borgCypressArchivesInfo" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(cat ${borgCypressCryptPasswdFile})
    ${pkgs.borgbackup}/bin/borg info ${config.backups.borgCypressRepo} 
    '';
in

{

  environment.variables = {
    BORG_PASSPHRASE = builtins.readFile "/run/secrets/borgCypressCryptPasswd";
  };

  sops.secrets.borgCypressCryptPasswd = {
    path = "/run/secrets/borgCypressCryptPasswd";
  };

  #environment.systemPackages = with pkgs; [ 
  #  borgCypressArchivesListScript 
  #  borgCypressArchivesInfoScript 
  #];

}