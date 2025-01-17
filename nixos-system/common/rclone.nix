{
  pkgs,
  lib,
  config,
  configVars,
  fileRcloneConf
  ...
}: 

let
  backblazeBackup = pkgs.writeShellScriptBin "backblazeBackup" ''
    #!/bin/bash
    echo "Running my custom script at $(date)" >> /var/log/my-custom-script.log
    sleep 30
    echo "Script finished at $(date)" >> /var/log/my-custom-script.log
    '';
in

{

  environment.systemPackages = with pkgs; [ backblazeBackup ];

  sops = {
    secrets = {
      backblazeAccount = {};
      backblazeKey = {};
    };
    templates = {
      "rclone.conf".content = ''
        [backblaze-b2]
        type = b2
        account = ${config.sops.placeholder.backblazeAccount}
        key = ${config.sops.placeholder.backblazeKey}
        hard_delete = true
      '';
    };
  };

  systemd.services."backblazeBackup".serviceConfig = (import ./lib/pg-db-archive.nix) {
    config = config;
    pkgs = pkgs;
    fileRcloneConf = "/run/secrets/rcloneConf";
  };
  
}  