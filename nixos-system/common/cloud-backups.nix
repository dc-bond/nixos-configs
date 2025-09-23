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
  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";

  cloudBackupScript = pkgs.writeShellScriptBin "cloudBackup" ''
    #!/bin/bash
    echo "rclone cloud backup to backblaze started at $(date)"
    ${pkgs.rclone}/bin/rclone --config "${rcloneConf}" --verbose sync ${config.backups.borgDir}/${config.networking.hostName} backblaze-b2:${config.networking.hostName}-backup-dcbond
    echo "rclone cloud backup to backblaze finished at $(date)"
  '';

  cloudRestoreScript = pkgs.writeShellScriptBin "cloudRestore" ''
    #!/bin/bash
    echo "rclone cloud restore from backblaze started at $(date)"
    if [ -d "${config.backups.borgCloudDir}/${config.networking.hostName}" ]; then
      echo "stale restoration detected at ${config.backups.borgCloudDir}/${config.networking.hostName}... deleting"
      rm -rf ${config.backups.borgCloudDir}/${config.networking.hostName}
    fi
    echo "creating restoration directory at ${config.backups.borgCloudDir}/${config.networking.hostName}"
    mkdir ${config.backups.borgCloudDir}/${config.networking.hostName}
    ${pkgs.rclone}/bin/rclone --config "${rcloneConf}" --verbose sync backblaze-b2:${config.networking.hostName}-backup-dcbond ${config.backups.borgCloudDir}/${config.networking.hostName}
    echo "change ownership of restoration directory at ${config.backups.borgCloudDir}/${config.networking.hostName}"
    chown -R root:root ${config.backups.borgCloudDir}/${config.networking.hostName}
    echo "rclone cloud restore from backblaze finished at $(date)"
  '';  

  listCloudArchivesScript = pkgs.writeShellScriptBin "listCloudArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    sudo -E ${pkgs.borgbackup}/bin/borg list --short ${config.backups.borgCloudDir}/${config.networking.hostName}
  '';

  infoCloudArchivesScript = pkgs.writeShellScriptBin "infoCloudArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    sudo -E ${pkgs.borgbackup}/bin/borg info ${config.backups.borgCloudDir}/${config.networking.hostName}
  '';

in

{

  sops = {
    secrets = {
      borgCryptPasswd = {};
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
    listCloudArchivesScript
    infoCloudArchivesScript
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
  };

}