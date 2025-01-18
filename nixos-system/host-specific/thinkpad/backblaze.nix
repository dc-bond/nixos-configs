{
  pkgs,
  lib,
  config,
  ...
}: 

let
  rcloneConf = "/run/secrets/rendered/rclone.conf";
  cypressBackupScript = pkgs.writeShellScriptBin "cypressBackup" ''
    #!/bin/bash
    echo "rclone cloud backup to backblaze started at $(date)"
    ${pkgs.rclone}/bin/rclone --config "${rcloneConf}" --verbose sync ${config.backups.borgCypressRepo} backblaze-b2:cypress-backup
    echo "rclone cloud backup to backblaze finished at $(date)"
    '';
  cypressRestoreScript = pkgs.writeShellScriptBin "cypressRestore" ''
    #!/bin/bash
    echo "rclone cloud restore from backblaze started at $(date)"
    if [ -d "${config.backups.borgCypressCloudRestoreRepo}" ]; then
      echo "stale restoration detected at ${config.backups.borgCypressCloudRestoreRepo}... deleting"
      rm -rf ${config.backups.borgCypressCloudRestoreRepo}
    fi
    echo "creating restoration directory at ${config.backups.borgCypressCloudRestoreRepo}"
    mkdir ${config.backups.borgCypressCloudRestoreRepo}
    ${pkgs.rclone}/bin/rclone --config "${rcloneConf}" --verbose sync backblaze-b2:cypress-backup ${config.backups.borgCypressCloudRestoreRepo}
    echo "change ownership of restoration directory at ${config.backups.borgCypressCloudRestoreRepo} to borg"
    chown -R borg:borg ${config.backups.borgCypressCloudRestoreRepo}
    echo "rclone cloud restore from backblaze finished at $(date)"
    '';
in

{

  environment.systemPackages = with pkgs; [ 
    cypressBackupScript
    cypressRestoreScript
    rclone
  ];

  sops = {
    secrets = {
      backblazeCypressAccount = {};
      backblazeCypressKey = {};
    };
    templates = {
      "rclone.conf".content = ''
        [backblaze-b2]
        type = b2
        account = ${config.sops.placeholder.backblazeCypressAccount}
        key = ${config.sops.placeholder.backblazeCypressKey}
        hard_delete = true
      '';
    };
  };

  systemd.services = {
    "cypressBackup" = {
      description = "rclone backup to backblaze cloud storage";
      serviceConfig = {
        ExecStart = "${cypressBackupScript}/bin/cypressBackup";
        Restart = "on-failure";
        EnvironmentFile = "${rcloneConf}";
      };
      preStart = ''
        if [ ! -f "${rcloneConf}" ]; then
          echo "rclone configuration file not found at ${rcloneConf}"
          exit 1
        fi
      '';
    };
    "cypressRestore" = {
      description = "rclone restore from backblaze cloud storage";
      serviceConfig = {
        ExecStart = "${cypressRestoreScript}/bin/cypressRestore";
        Restart = "on-failure";
        EnvironmentFile = "${rcloneConf}";
      };
      preStart = ''
        if [ ! -f "${rcloneConf}" ]; then
          echo "rclone configuration file not found at ${rcloneConf}"
          exit 1
        fi
      '';

    };
  };
  
}  