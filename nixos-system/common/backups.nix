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
    export BORG_PASSPHRASE=$(cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    ${pkgs.borgbackup}/bin/borg list --short ${config.backups.borgDir}/${config.networking.hostName}
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
    export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
    sudo -E ${pkgs.borgbackup}/bin/borg list --short ${config.backups.borgCloudDir}/${config.networking.hostName}
  '';

  infoCloudArchivesScript = pkgs.writeShellScriptBin "infoCloudArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
    sudo -E ${pkgs.borgbackup}/bin/borg info ${config.backups.borgCloudDir}/${config.networking.hostName}
  '';
  
  dockerServiceRecoveryScript = { 
    serviceName, 
    recoveryPlan 
  }: # function that generates a standardized recovery script for any dockerized container stack service
    pkgs.writeShellScriptBin "recover${lib.strings.toUpper (builtins.substring 0 1 serviceName)}${builtins.substring 1 (-1) serviceName}" ''
      #!/bin/bash
     
      # track errors
      set -euo pipefail

      # set borg passphrase environment variable
      export BORG_PASSPHRASE=$(cat ${borgCryptPasswdFile})
      export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

      # repo selection
      read -p "Use cloud repo? (y/N): " use_cloud
      if [[ "$use_cloud" =~ ^[Yy]$ ]]; then
        REPO="${recoveryPlan.cloudRestoreRepoPath}"
        echo "Using cloud repo"
      else
        REPO="${recoveryPlan.localRestoreRepoPath}"
        echo "Using local repo"
      fi

      # archive selection
      echo "Available archives at $REPO:"
      echo ""
      archives=$(${pkgs.borgbackup}/bin/borg list --short "$REPO")
      echo "$archives" | nl -w2 -s') '
      echo ""
      read -p "Enter number: " num
      ARCHIVE=$(echo "$archives" | sed -n "''${num}p")
      if [ -z "$ARCHIVE" ]; then
        echo "Invalid selection"
        exit 1
      fi
      echo "Selected: $ARCHIVE"

      # stop services
      for svc in ${lib.concatStringsSep " " recoveryPlan.stopServices}; do
        echo "Stopping $svc ..."
        systemctl stop "$svc" || true
      done

      # allow for graceful container shutdown
      echo "Ensure container stack fully down..."
      sleep 15 
      
      # extract volume names from restore items
      VOLUMES=""
      for item in ${lib.concatStringsSep " " recoveryPlan.restoreItems}; do
        VOLUME_NAME=$(basename "$item")
        VOLUMES="$VOLUMES $VOLUME_NAME"
      done
      
      # remove existing volumes
      echo "Removing existing volumes..."
      for volume in $VOLUMES; do
        echo "Removing volume: $volume"
        ${pkgs.docker}/bin/docker volume rm "$volume" || true
      done
      
      # recreate volumes
      echo "Recreating volumes..."
      for volume in $VOLUMES; do
        echo "Creating volume: $volume"
        ${pkgs.docker}/bin/docker volume create "$volume"
      done

      # extract data from archive
      cd /
      echo "Extracting data from $REPO::$ARCHIVE ..."
      ${pkgs.borgbackup}/bin/borg extract --verbose --list "$REPO"::"$ARCHIVE" ${lib.concatStringsSep " " recoveryPlan.restoreItems}

      # start services
      for svc in ${lib.concatStringsSep " " recoveryPlan.startServices}; do
        echo "Starting $svc ..."
        systemctl start "$svc" || true
      done

      echo "Recovery complete for ${serviceName}!"
    '';

  nixServiceRecoveryScript = {
    serviceName,
    recoveryPlan,
    dbType ? null, # "postgresql", "mysql", or null
    preRestoreHook ? "", # custom commands before starting restoration (e.g. turn on nextcloud maintenance mode)
    postSvcStopHook ? "", # custom commands after stopping services but before data restoration (e.g. allow graceful shutdown of database connections)
    preSvcStartHook ? "", # custom commands before re-starting restored services
    postRestoreHook ? "", # custom commands after full restoration
  }: # function that generates a standardized recovery script for any nix module service
    pkgs.writeShellScriptBin "recover${lib.strings.toUpper (lib.substring 0 1 serviceName)}${lib.substring 1 (-1) serviceName}" ''
      #!/bin/bash

      # track errors
      set -euo pipefail

      # set borg passphrase environment variable
      export BORG_PASSPHRASE=$(cat ${borgCryptPasswdFile})
      export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

      # repo selection
      read -p "Use cloud repo? (y/N): " use_cloud
      if [[ "$use_cloud" =~ ^[Yy]$ ]]; then
        REPO="${recoveryPlan.cloudRestoreRepoPath}"
        echo "Using cloud repo"
      else
        REPO="${recoveryPlan.localRestoreRepoPath}"
        echo "Using local repo"
      fi

      # archive selection
      echo "Available archives at $REPO:"
      echo ""
      archives=$(${pkgs.borgbackup}/bin/borg list --short "$REPO")
      echo "$archives" | nl -w2 -s') '
      echo ""
      read -p "Enter number: " num
      ARCHIVE=$(echo "$archives" | sed -n "''${num}p")
      if [ -z "$ARCHIVE" ]; then
        echo "Invalid selection"
        exit 1
      fi
      echo "Selected: $ARCHIVE"
    
      # pre restore hook
      ${preRestoreHook}
    
      # stop services
      for svc in ${lib.concatStringsSep " " recoveryPlan.stopServices}; do
        echo "Stopping $svc ..."
        systemctl stop "$svc" || true
      done

      # post service stop hook
      ${postSvcStopHook}
    
      # extract data from archive and overwrite existing data
      cd /
      echo "Extracting data from $REPO::$ARCHIVE ..."
      ${pkgs.borgbackup}/bin/borg extract --verbose --list "$REPO"::"$ARCHIVE" ${lib.concatStringsSep " " recoveryPlan.restoreItems}
      
      # drop and recreate database if postgres
      ${lib.optionalString (dbType == "postgresql") ''
        echo "Dropping and recreating PostgreSQL database ${recoveryPlan.db.name} ..."
        su - postgres -c "dropdb --if-exists ${recoveryPlan.db.name}"
        su - postgres -c "createdb -O ${recoveryPlan.db.user} ${recoveryPlan.db.name}"
        echo "Restoring database from ${recoveryPlan.db.dump} ..."
        gunzip -c ${recoveryPlan.db.dump} | su - postgres -c "psql ${recoveryPlan.db.name}"
      ''}
      
      # drop and recreate database if mysql
      ${lib.optionalString (dbType == "mysql") ''
        echo "Dropping and recreating MySQL database ${recoveryPlan.db.name} ..."
        sudo -u mysql mysql -e "DROP DATABASE IF EXISTS ${recoveryPlan.db.name};"
        sudo -u mysql mysql -e "CREATE DATABASE ${recoveryPlan.db.name};"
        sudo -u mysql mysql -e "GRANT ALL PRIVILEGES ON ${recoveryPlan.db.name}.* TO '${recoveryPlan.db.user}'@'localhost';"
        echo "Restoring database from ${recoveryPlan.db.dump} ..."
        gunzip -c ${recoveryPlan.db.dump} | sudo -u mysql mysql ${recoveryPlan.db.name}
      ''}
    
      # pre service start hook
      ${preSvcStartHook}
    
      # start services
      for svc in ${lib.concatStringsSep " " recoveryPlan.startServices}; do
        echo "Starting $svc ..."
        systemctl start "$svc" || true
      done
    
      # post restore hook
      ${postRestoreHook}
    
      echo "Recovery complete!"
    '';

    borgCheckLocalScript = pkgs.writeShellScriptBin "borgCheckLocal" ''
        #!/bin/bash
        set -euo pipefail
        
        export BORG_PASSPHRASE=$(cat ${borgCryptPasswdFile})
        export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
        echo "Starting borg consistency check ..."
        ${pkgs.borgbackup}/bin/borg check --progress ${config.backups.borgDir}/${config.networking.hostName}
        echo "Borg check completed successfully at $(date) ..."
      '';
        #echo "Running daily consistency check ..."
        #${pkgs.borgbackup}/bin/borg check --progress "$REPO"
        #
        #if [[ "$(date +%u)" == "7" ]]; then
        #  echo "Running weekly full data verification check ..."
        #  ${pkgs.borgbackup}/bin/borg check --verify-data --progress "$REPO"
        #fi

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
    startTime = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 00:45:00"; # default everyday at 12:45am, override with alternate time in host-specific configuration.nix
      description = "when to start the backup (systemd timer format)";
    };
    serviceHooks = {
      preHook = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "commands to run before stopping services";
      };
      postHook = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "commands to run after starting services";
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
      borgCheckLocalScript
      rclone
    ];

    _module.args = {
      dockerServiceRecoveryScript = dockerServiceRecoveryScript;
      nixServiceRecoveryScript = nixServiceRecoveryScript;
    };

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
        startAt = config.backups.startTime;
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
          ${lib.concatStringsSep "\n" config.backups.serviceHooks.preHook}
        '';
        postHook = lib.mkDefault ''
          set -x
          echo "spinning up services"
          ${lib.concatStringsSep "\n" config.backups.serviceHooks.postHook}
          echo "starting cloud backup"
          systemctl start cloudBackup.service
        '';
        paths = lib.mkDefault [];
        prune.keep = {
          daily = 30; # keep the last thirty daily archives
          weekly = 4; # keep the last four weekly archives (following exhaustion of the daily archives)
          monthly = 3; # keep the last three monthly archives (following exhaustion of the weekly archives)
        };
      };
    };

    systemd = {
      services = {
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
    
  };

}