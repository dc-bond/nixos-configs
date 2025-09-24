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

  listLocalArchivesScript = pkgs.writeShellScriptBin "listLocalArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    sudo -E ${pkgs.borgbackup}/bin/borg list --short ${config.backups.borgDir}/${config.networking.hostName}
  '';

  infoLocalArchivesScript = pkgs.writeShellScriptBin "infoLocalArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    sudo -E ${pkgs.borgbackup}/bin/borg info ${config.backups.borgDir}/${config.networking.hostName}
  '';
  
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
    export BORG_CACHE_DIR=/tmp/borg-cloud-cache
    sudo -E ${pkgs.borgbackup}/bin/borg list --short ${config.backups.borgCloudDir}/${config.networking.hostName}
  '';

  infoCloudArchivesScript = pkgs.writeShellScriptBin "infoCloudArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    export BORG_CACHE_DIR=/tmp/borg-cloud-cache
    sudo -E ${pkgs.borgbackup}/bin/borg info ${config.backups.borgCloudDir}/${config.networking.hostName}
  '';

in

{

  options.backups = {
    borgDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/borgbackup"; # default, override with different directory in host-specific configuration.nix
      description = "path to the directory for borg backups";
    };
    borgCloudDir = lib.mkOption {
      type = lib.types.path;
      default = "${config.backups.borgDir}/cloud-restore";
      description = "path to the directory for borg backups restored from cloud storage (e.g. backblaze)";
    };
    serviceHooks = {
      preStop = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Commands to run before stopping services";
      };
      postStart = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Commands to run after starting services";
      };
    };
  };
  
  config = {

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
      listLocalArchivesScript
      infoLocalArchivesScript
      cloudBackupScript
      cloudRestoreScript
      listCloudArchivesScript
      infoCloudArchivesScript
      rclone
    ];

    services.borgbackup.jobs = {
      "${config.networking.hostName}" = {
        archiveBaseName = "${config.networking.hostName}";
        repo = "${config.backups.borgDir}/${config.networking.hostName}";
        dateFormat = "+%Y.%m.%d-T%H:%M:%S";
        doInit = true; # run borg init if backup directory does not already contain the repository
        failOnWarnings = false;
        extraCreateArgs = [
          "--progress"
          "--stats"
        ];
        startAt = "*-*-* 02:45:00"; # everyday at 2:45am
        encryption = {
          mode = "repokey-blake2"; # encrypt using password and save encryption key inside repository
          passCommand = "cat ${config.sops.secrets.borgCryptPasswd.path}";
        };
        environment = { 
          BORG_RELOCATED_REPO_ACCESS_IS_OK = "yes"; # supress warning about repo location being moved since last backup (e.g. changing directory location or IP address)
        };
        compression = "auto,zstd,8";
        preHook = lib.mkDefault ''
          set -x
          echo "spinning down services and starting sql database dumps"
          ${lib.concatStringsSep "\n" config.backups.serviceHooks.preStop}
        '';
        postHook = lib.mkDefault ''
          set -x
          echo "spinning up services"
          ${lib.concatStringsSep "\n" config.backups.serviceHooks.postStart}
          echo "starting cloud backup"
          systemctl start cloudBackup.service
        '';
        paths = lib.mkDefault [];
        prune.keep = {
          daily = 7; # keep the last seven daily archives
          monthly = 3; # keep the last three monthly archives
        };
      };
    };

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
    
  };

}