{
  pkgs,
  lib,
  config,
  configVars,
  fileRcloneConf,
  ...
}: 

let
  backblazeBackupScript = pkgs.writeShellScriptBin "backblazeBackup" ''
    #!/bin/bash
    echo "rclone backup sync started at $(date)"
    ${pkgs.rclone}/bin/rclone --config "${fileRcloneConf}" sync /var/lib/borg-backups/cypress backblaze-b2:cypress-backup
    echo "rclone backup sync finished at $(date)"
    '';
in

{

  environment.systemPackages = with pkgs; [ 
    backblazeBackupScript
    rclone
  ];

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

  systemd.services."backblazeBackup" = {
    description = "rclone backup to backblaze cloud storage";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${backblazeBackupScript}/bin/backblazeBackup";
      Restart = "on-failure";
      EnvironmentFile = "/run/secrets/rclone.conf";
    };
    preStart = ''
      if [ ! -f "${fileRcloneConf}" ]; then
        echo "rclone configuration file not found at ${fileRcloneConf}"
        exit 1
      fi
    '';
  };
  
}  