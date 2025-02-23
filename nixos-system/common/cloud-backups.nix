{ 
  pkgs,
  config,
  lib,
  configVars,
  configLib,
  ... 
}: 

let
  rcloneConf = "/run/secrets/rendered/rclone.conf";
  cloudBackupScript = pkgs.writeShellScriptBin "cloudBackup" ''
    #!/bin/bash
    echo "rclone cloud backup to backblaze started at $(date)"
    ${pkgs.rclone}/bin/rclone --config "${rcloneConf}" --verbose sync ${config.backups.borgDir}/${config.networking.hostName} backblaze-b2:${config.networking.hostName}-backup
    echo "rclone cloud backup to backblaze finished at $(date)"
    '';
  cloudRestoreScript = pkgs.writeShellScriptBin "cloudRestore" ''
    #!/bin/bash

    # define available hosts
    HOSTS=("aspen", "cypress" "thinkpad")
    
    # display menu options for hosts
    echo "Select a host to recover:"
    for i in "''${!HOSTS[@]}"; do
      echo "$((i+1))) ''${HOSTS[$i]}"
    done
    
    # obtain target host from user
    read -p "Enter the number of your choice for a host: " CHOICE
    
    # validate host selection
    if [[ ! "$CHOICE" =~ ^[1-3]$ ]]; then
      echo "Error: Invalid selection."
      exit 1
    fi
   
    # set the selected host
    HOST="''${HOSTS[$((CHOICE-1))]}"

    echo "rclone cloud restore from backblaze started at $(date)"
    if [ -d "${config.backups.borgCloudDir}/$HOST" ]; then
      echo "stale restoration detected at ${config.backups.borgCloudDir}/$HOST... deleting"
      rm -rf ${config.backups.borgCloudDir}/$HOST
    fi
    echo "creating restoration directory at ${config.backups.borgCloudDir}/$HOST"
    mkdir ${config.backups.borgCloudDir}/$HOST
    ${pkgs.rclone}/bin/rclone --config "${rcloneConf}" --verbose sync backblaze-b2:$HOST-backup ${config.backups.borgCloudDir}/$HOST
    echo "change ownership of restoration directory at ${config.backups.borgCloudDir}/$HOST to borg"
    chown -R borg:borg ${config.backups.borgCloudDir}/$HOST
    echo "rclone cloud restore from backblaze finished at $(date)"
    '';
in

{

  sops = {
    secrets = {
      backblazeMasterAppKeyId = {}; # aka "account" for rclone
      backblazeMasterAppKey = {}; # aka "key" for rclone
    };
    templates = {
      "rclone.conf".content = ''
        [backblaze-b2]
        type = b2
        account = ${config.sops.placeholder.backblazeMasterAppKeyId}
        key = ${config.sops.placeholder.backblazeMasterAppKey}
        hard_delete = true
      '';
    };
  };
 
  environment.systemPackages = with pkgs; [ 
    cloudBackupScript
    cloudRestoreScript
    rclone
  ];

  systemd.services = {
    "cloudBackup" = {
      description = "rclone backup to backblaze cloud storage";
      serviceConfig = {
        ExecStart = "${cloudBackupScript}/bin/cloudBackup";
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
    "cloudRestore" = {
      description = "rclone restore from backblaze cloud storage";
      serviceConfig = {
        ExecStart = "${cloudRestoreScript}/bin/cloudRestore";
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