{
  pkgs,
  lib,
  config,
  configVars,
  fileRcloneConf
  ...
}: 

let
  rcloneRun = pkgs.writeShellScriptBin "rcloneRun" ''
    #!/bin/bash
    echo "Running my custom script at $(date)" >> /var/log/my-custom-script.log
    sleep 30
    echo "Script finished at $(date)" >> /var/log/my-custom-script.log
    '';
in

{

  environment.systemPackages = with pkgs; [ rcloneRun ];

  sops = {
    secrets = {
      rcloneSecret = {};
    };
    templates = {
      "rclone.conf".content = ''
        LLDAP_JWT_SECRET=${config.sops.placeholder.lldapJwtSecret}
      '';
    };
  };

  systemd.services."rcloneBackup".serviceConfig = (import ./lib/pg-db-archive.nix) {
    config = config;
    pkgs = pkgs;
    fileEncKey = "/run/secrets/keys/db2";
    fileRcloneConf = "/run/secrets/rcloneConf";
  };
  
}  