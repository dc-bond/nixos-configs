{ 
  pkgs,
  config,
  lib,
  configVars,
  ... 
}: 

let

  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";

  listLocalArchivesScript = pkgs.writeShellScriptBin "listLocalArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    sudo -E ${pkgs.borgbackup}/bin/borg list ${config.backups.borgDir}/${config.networking.hostName}
    '';

  infoLocalArchivesScript = pkgs.writeShellScriptBin "infoLocalArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    sudo -E ${pkgs.borgbackup}/bin/borg info ${config.backups.borgDir}/${config.networking.hostName}
    '';

in

{
  
  options.backups = {
    borgDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/borgbackup";
      description = "path to the directory for borg backups";
    };
    borgCloudDir = lib.mkOption {
      type = lib.types.path;
      default = "${config.backups.borgDir}/cloud-restore";
      description = "path to the directory for borg backups restored from cloud storage (e.g. backblaze)";
    };
  };

  config = {

    sops.secrets.borgCryptPasswd = {};

    environment.systemPackages = with pkgs; [ 
      listLocalArchivesScript
      infoLocalArchivesScript
    ];

  #  services.borgbackup.repos = {
  #    cypress = {
  #      authorizedKeys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOpolyGOcVqcrl1Kp+brigrMsrD9R194SGG9+L5ubZe3 borg@cypress"];
  #      path = "${config.backups.borgDir}/cypress";
  #    };
  #  };

  };

}