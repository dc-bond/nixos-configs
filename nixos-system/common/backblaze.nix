{
  pkgs,
  lib,
  config,
  ...
}: 

let
  rcloneConf = "/run/secrets/rendered/rclone.conf";
  borgCypressRepo = "/var/lib/borg-backups/cypress";
  borgCypressRestoreDir = "/var/lib/borg-backups/cypress-cloud-restore";
  cypressBackupScript = pkgs.writeShellScriptBin "cypressBackupScript" ''
    #!/bin/bash
    echo "rclone cloud backup to backblaze started at $(date)"
    ${pkgs.rclone}/bin/rclone --config "${rcloneConf}" --verbose sync ${borgCypressRepo} backblaze-b2:cypress-backup
    echo "rclone cloud backup to backblaze finished at $(date)"
    '';
  cypressRestoreScript = pkgs.writeShellScriptBin "cypressRestoreScript" ''
    #!/bin/bash
    echo "rclone cloud restore from backblaze started at $(date)"
    if [ -f "${borgCypressRestoreDir}" ]; then
      echo "stale restoration detected at ${borgCypressRestoreDir}... deleting"
      rm -rf ${borgCypressRestoreDir}
    fi
    echo "creating restoration directory at ${borgCypressRestoreDir}"
    mkdir ${borgCypressRestoreDir}
    ${pkgs.rclone}/bin/rclone --config "${rcloneConf}" --verbose sync backblaze-b2:cypress-backup ${borgCypressRestoreDir}
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

  systemd.services = {
    "cypressBackupScript" = {
      description = "rclone backup to backblaze cloud storage";
      serviceConfig = {
        ExecStart = "${cypressBackupScript}/bin/cypressBackupScript";
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
    "cypressRestoreScript" = {
      description = "rclone restore from backblaze cloud storage";
      serviceConfig = {
        ExecStart = "${cypressRestoreScript}/bin/cypressRestoreScript";
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