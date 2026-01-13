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
  chrisEmailPasswd = "/run/secrets/chrisEmailPasswd";

  initLocalRepoScript = pkgs.writeShellScriptBin "initLocalRepo" ''
    #!/bin/bash
    set -euo pipefail
    export BORG_PASSPHRASE=$(cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    mkdir -p ${config.backups.borgDir}/${config.networking.hostName}
    borg init --encryption=repokey-blake2 ${config.backups.borgDir}/${config.networking.hostName}
    echo "repository initialized successfully"
  '';

  cloudBackupScript = pkgs.writeShellScriptBin "cloudBackup" ''
    #!/bin/bash
    set -euo pipefail
    
    echo "starting cloud backup validation and sync..."
    
    export BORG_PASSPHRASE=$(cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

    if [[ "$(date +%u)" == "7" ]]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') - running full data verification check (Sunday)..."
      ${pkgs.borgbackup}/bin/borg check --verify-data ${config.backups.borgDir}/${config.networking.hostName}
    else
      echo "$(date '+%Y-%m-%d %H:%M:%S') - running standard integrity check..."
      ${pkgs.borgbackup}/bin/borg check ${config.backups.borgDir}/${config.networking.hostName}
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') - repository integrity check completed - starting cloud sync"
    ${pkgs.rclone}/bin/rclone --config "${rcloneConf}" --verbose sync ${config.backups.borgDir}/${config.networking.hostName} backblaze-b2:${config.networking.hostName}-backup-dcbond
    
    echo "cloud backup completed successfully"
  '';

  backupSuccessWebhookScript = pkgs.writeShellScriptBin "backupSuccessWebhook" ''
    #!/bin/bash

    TIMESTAMP="$(date "+%Y-%m-%d %H:%M:%S")"

    ${pkgs.curl}/bin/curl -X POST \
      -H "Content-Type: application/json" \
      -d @- \
      "${configVars.webhooks.matrixBackupNotifications}" <<EOF
    {
      "text": "✅ **Backup Success - ${config.networking.hostName}**\n\nTime: $TIMESTAMP\n\nLocal backup and cloud sync completed successfully."
    }
    EOF
  '';

  backupSuccessEmailScript = pkgs.writeShellScriptBin "backupSuccessEmail" ''
    #!/bin/bash

    {
      echo "Subject: Nightly Backup SUCCESS - ${config.networking.hostName}"
      echo "To: ${configVars.users.chris.email}"
      echo "From: ${configVars.users.chris.email}"
      echo ""
      echo "Time: $(date "+%Y-%m-%d %H:%M:%S")"
    } | ${pkgs.msmtp}/bin/msmtp \
      --host=${configVars.mailservers.namecheap.smtpHost} \
      --port=${toString configVars.mailservers.namecheap.smtpPort} \
      --auth=on \
      --user=${configVars.users.chris.email} \
      --passwordeval "cat ${chrisEmailPasswd}" \
      --tls=on \
      --tls-starttls=on \
      --from=${configVars.users.chris.email} \
      -t
  '';

  backupFailureWebhookScript = pkgs.writeShellScriptBin "backupFailureWebhook" ''
    #!/bin/bash

    EXIT_CODE=$(systemctl show cloudBackup.service --property=ExecMainStatus --value)
    TIMESTAMP="$(date "+%Y-%m-%d %H:%M:%S")"

    ${pkgs.curl}/bin/curl -X POST \
      -H "Content-Type: application/json" \
      -d @- \
      "${configVars.webhooks.matrixBackupNotifications}" <<EOF
    {
      "text": "🚨 **BACKUP FAILED - ${config.networking.hostName}**\n\n⚠️ IMMEDIATE ACTION REQUIRED!\n\n**Exit Code**: $EXIT_CODE\n\n**Possible Causes**:\n- Local backup failure\n- Repository corruption\n- Low archive count\n- Network/Backblaze issues\n- Service configuration problems\n\n**Time**: $TIMESTAMP\n\n**Action**: Check logs with \`jlogs cloudBackup\`"
    }
    EOF
  '';

  backupFailureEmailScript = pkgs.writeShellScriptBin "backupFailureEmail" ''
    #!/bin/bash

    EXIT_CODE=$(systemctl show cloudBackup.service --property=ExecMainStatus --value)

    {
      echo "Subject: Nightly Backup FAILED - ${config.networking.hostName}"
      echo "To: ${configVars.users.chris.email}"
      echo "From: ${configVars.users.chris.email}"
      echo ""
      echo "CRITICAL: Backup process FAILED!"
      echo ""
      echo "This could indicate:"
      echo "- Local backup failure prior to cloud backup"
      echo "- Repository corruption or integrity issues"
      echo "- Low archive count (possible repo re-initialization)"
      echo "- Network/Backblaze connectivity problems"
      echo "- Service configuration issues"
      echo ""
      echo "Exit code: $EXIT_CODE"
      echo "Time: $(date "+%Y-%m-%d %H:%M:%S")"
      echo ""
      echo "Check logs: jlogs cloudBackup"
      echo ""
      echo "IMMEDIATE ACTION REQUIRED!"
    } | ${pkgs.msmtp}/bin/msmtp \
      --host=${configVars.mailservers.namecheap.smtpHost} \
      --port=${toString configVars.mailservers.namecheap.smtpPort} \
      --auth=on \
      --user=${configVars.users.chris.email} \
      --passwordeval "cat ${chrisEmailPasswd}" \
      --tls=on \
      --tls-starttls=on \
      --from=${configVars.users.chris.email} \
      -t
  '';

  inspectLocalBackupsScript = pkgs.writeShellScriptBin "inspectLocalBackups" ''
    #!/bin/bash
    set -euo pipefail
    export BORG_PASSPHRASE=$(cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    
    LOCAL_REPO="${config.backups.borgDir}/${config.networking.hostName}"
    
    echo "=========================================="
    echo "REPOSITORY INFO"
    echo "=========================================="
    ${pkgs.borgbackup}/bin/borg info "$LOCAL_REPO"
    
    echo ""
    echo "=========================================="
    echo "AVAILABLE ARCHIVES"
    echo "=========================================="
    ${pkgs.borgbackup}/bin/borg list --short "$LOCAL_REPO"
    
    echo ""
    echo "Inspection complete!"
  '';

  inspectRemoteBackupsScript = pkgs.writeShellScriptBin "inspectRemoteBackups" ''
    #!/bin/bash
    
    set -euo pipefail
    export BORG_PASSPHRASE=$(cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    
    TEMP_MOUNT=""
    
    # cleanup function
    cleanup() {
      if [ -n "$TEMP_MOUNT" ] && [ -d "$TEMP_MOUNT" ]; then
        echo ""
        echo "Cleaning up..."
        if mountpoint -q "$TEMP_MOUNT" 2>/dev/null; then
          fusermount -u "$TEMP_MOUNT" 2>/dev/null || umount "$TEMP_MOUNT" 2>/dev/null || true
        fi
        rmdir "$TEMP_MOUNT" 2>/dev/null || true
      fi
    }
    
    # register cleanup on exit
    trap cleanup EXIT INT TERM
    
    # generate list of available hosts
    HOSTS=(${lib.concatStringsSep " " (builtins.attrNames configVars.hosts)})
    
    echo "Available hosts:"
    for i in "''${!HOSTS[@]}"; do
      if [ "''${HOSTS[$i]}" = "${config.networking.hostName}" ]; then
        echo "$((i+1))) ''${HOSTS[$i]} (current host)"
      else
        echo "$((i+1))) ''${HOSTS[$i]}"
      fi
    done
    echo ""
    
    read -p "Select host number [1]: " host_num
    host_num=''${host_num:-1}
    
    # validate selection
    if ! [[ "$host_num" =~ ^[0-9]+$ ]] || [ "$host_num" -lt 1 ] || [ "$host_num" -gt "''${#HOSTS[@]}" ]; then
      echo "Invalid selection"
      exit 1
    fi
    
    SOURCE_HOST="''${HOSTS[$((host_num-1))]}"
    echo "Selected: $SOURCE_HOST"
    echo ""
    
    TEMP_MOUNT="/tmp/borg-inspect-$SOURCE_HOST-$$"
    mkdir -p "$TEMP_MOUNT"
    
    echo "Mounting remote backup from $SOURCE_HOST..."
    ${pkgs.rclone}/bin/rclone mount \
      --config "${rcloneConf}" \
      --vfs-cache-mode writes \
      --allow-other \
      --daemon \
      backblaze-b2:$SOURCE_HOST-backup-dcbond "$TEMP_MOUNT"
    
    sleep 5
    
    if ! mountpoint -q "$TEMP_MOUNT"; then
      echo "ERROR: Failed to mount remote repository"
      exit 1
    fi
    
    echo "Repository mounted successfully"
    echo ""
    echo "=========================================="
    echo "REPOSITORY INFO"
    echo "=========================================="
    ${pkgs.borgbackup}/bin/borg info "$TEMP_MOUNT"
    
    echo ""
    echo "=========================================="
    echo "AVAILABLE ARCHIVES"
    echo "=========================================="
    ${pkgs.borgbackup}/bin/borg list "$TEMP_MOUNT"
    
    echo ""
    echo "Inspection complete!"
  '';

  dockerServiceRecoveryScript = { 
  serviceName, 
  recoveryPlan 
  }: # function that generates a standardized recovery script for any oci-container module service
  pkgs.writeShellScriptBin "recover${lib.strings.toUpper (builtins.substring 0 1 serviceName)}${builtins.substring 1 (-1) serviceName}" ''
    #!/bin/bash
   
    set -euo pipefail
    export BORG_PASSPHRASE=$(cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

    TEMP_MOUNT=""
    TEMP_EXTRACT=""
    EXTRACT_TO_TEMP=false
    CLEANUP_MOUNT=false

    # cleanup function
    cleanup() {
      if [ "$CLEANUP_MOUNT" = true ] && [ -n "$TEMP_MOUNT" ] && [ -d "$TEMP_MOUNT" ]; then
        echo "Cleaning up remote mount..."
        if mountpoint -q "$TEMP_MOUNT" 2>/dev/null; then
          fusermount -u "$TEMP_MOUNT" 2>/dev/null || umount "$TEMP_MOUNT" 2>/dev/null || true
        fi
        rmdir "$TEMP_MOUNT" 2>/dev/null || true
      fi
      if [ -n "$TEMP_EXTRACT" ] && [ -d "$TEMP_EXTRACT" ]; then
        echo "Cleaning up temp extraction..."
        rm -rf "$TEMP_EXTRACT"
      fi
    }

    # register cleanup on exit
    trap cleanup EXIT INT TERM

    echo "========================================"
    echo "Recovery: ${serviceName}"
    echo "========================================"
    echo ""

    # repo source selection
    echo "Select repository source:"
    echo "  L) Local repository"
    echo "  R) Remote repository (Backblaze B2)"
    echo ""
    read -p "Source [L]: " repo_type
    repo_type=''${repo_type:-L}
    
    if [[ "$repo_type" =~ ^[Rr]$ ]]; then

      # remote: host selection
      HOSTS=(${lib.concatStringsSep " " (builtins.attrNames configVars.hosts)})
      
      echo ""
      echo "Available hosts:"
      for i in "''${!HOSTS[@]}"; do
        if [ "''${HOSTS[$i]}" = "${config.networking.hostName}" ]; then
          echo "  $((i+1))) ''${HOSTS[$i]} (current host)"
        else
          echo "  $((i+1))) ''${HOSTS[$i]}"
        fi
      done
      echo ""
      
      read -p "Select host [1]: " host_num
      host_num=''${host_num:-1}
      
      if ! [[ "$host_num" =~ ^[0-9]+$ ]] || [ "$host_num" -lt 1 ] || [ "$host_num" -gt "''${#HOSTS[@]}" ]; then
        echo "Invalid selection"
        exit 1
      fi
      
      SOURCE_HOST="''${HOSTS[$((host_num-1))]}"
      echo "Selected: $SOURCE_HOST"
      
      # mount remote
      TEMP_MOUNT="/tmp/borg-mount-$$"
      mkdir -p "$TEMP_MOUNT"
      
      echo ""
      echo "Mounting remote backup from $SOURCE_HOST via Backblaze B2..."
      echo "This may take a few moments..."
      ${pkgs.rclone}/bin/rclone mount \
        --config "${rcloneConf}" \
        --vfs-cache-mode writes \
        --allow-other \
        --daemon \
        backblaze-b2:$SOURCE_HOST-backup-dcbond "$TEMP_MOUNT"
      
      # wait for mount to be ready
      sleep 5
      
      # verify mount succeeded
      if ! mountpoint -q "$TEMP_MOUNT"; then
        echo "ERROR: Failed to mount remote repository"
        exit 1
      fi
      
      REPO="$TEMP_MOUNT"
      CLEANUP_MOUNT=true
      EXTRACT_TO_TEMP=true
      echo "Remote repository mounted"
      
    else
    
      # use local repository
      REPO="${config.backups.borgDir}/${config.networking.hostName}"
      
      # verify local repo exists
      if [ ! -d "$REPO" ]; then
        echo "ERROR: Local repository not found at $REPO"
        exit 1
      fi
      
      echo "Using local repository: $REPO"
    fi

    # archive selection
    echo ""
    echo "Fetching archives..."
    archives=$(${pkgs.borgbackup}/bin/borg list --short "$REPO")
    
    if [ -z "$archives" ]; then
      echo "ERROR: No archives found"
      exit 1
    fi
    
    echo ""
    echo "Available archives:"
    echo "$archives" | nl -w2 -s') '
    echo ""
    read -p "Select archive: " num
    
    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
      echo "Invalid selection"
      exit 1
    fi
    
    ARCHIVE=$(echo "$archives" | sed -n "''${num}p")
    
    if [ -z "$ARCHIVE" ]; then
      echo "Invalid selection"
      exit 1
    fi
    
    echo "Selected: $ARCHIVE"

    # extract data before bringing services down (if remote)
    if [ "$EXTRACT_TO_TEMP" = true ]; then
      echo ""
      echo "========================================"
      echo "Phase 1: downloading data"
      echo "========================================"
      
      TEMP_EXTRACT="/tmp/borg-extract-$$"
      mkdir -p "$TEMP_EXTRACT"
      
      echo ""
      echo "Extracting to /tmp..."
      
      cd "$TEMP_EXTRACT"
      if ! ${pkgs.borgbackup}/bin/borg extract --verbose --list "$REPO"::"$ARCHIVE" ${lib.concatStringsSep " " recoveryPlan.restoreItems}; then
        echo ""
        echo "ERROR: Extraction failed. No changes made to services."
        exit 1
      fi
      
      echo ""
      echo "✓ Data downloaded successfully"
      
      # unmount remote
      fusermount -u "$TEMP_MOUNT" 2>/dev/null || true
      rmdir "$TEMP_MOUNT" 2>/dev/null || true
      CLEANUP_MOUNT=false
    fi

    echo ""
    echo "========================================"
    echo "Phase 2: applying recovery"
    echo "========================================"
    echo ""
    echo "This will:"
    echo "  Stop: ${lib.concatStringsSep ", " recoveryPlan.stopServices}"
    echo "  Replace Docker service volume data"
    echo ""
    read -p "Proceed? (y/N): " confirm
    if ! [[ "$confirm" =~ ^[Yy]$ ]]; then
      echo "Aborted. No changes made."
      exit 0
    fi

    echo ""
    echo "Stopping services..."
    for svc in ${lib.concatStringsSep " " recoveryPlan.stopServices}; do
      systemctl stop "$svc" || true
    done

    echo "Waiting for graceful container shutdown..."
    sleep 15 
    
    # extract volume names from restore items
    VOLUMES=""
    for item in ${lib.concatStringsSep " " recoveryPlan.restoreItems}; do
      VOLUME_NAME=$(basename "$item")
      VOLUMES="$VOLUMES $VOLUME_NAME"
    done
    
    echo "Removing existing volumes..."
    for volume in $VOLUMES; do
      ${pkgs.docker}/bin/docker volume rm "$volume" 2>/dev/null || true
    done
    
    echo "Recreating volumes..."
    for volume in $VOLUMES; do
      ${pkgs.docker}/bin/docker volume create "$volume"
    done

    # copy (if remote) or direct extract (if local) recovery data
    if [ "$EXTRACT_TO_TEMP" = true ]; then
      echo "Moving data to final location..."
      for item in ${lib.concatStringsSep " " recoveryPlan.restoreItems}; do
        if [ ! -e "$TEMP_EXTRACT$item" ]; then
          echo "ERROR: Extracted data not found at $TEMP_EXTRACT$item"
          exit 1
        fi
        cp -av "$TEMP_EXTRACT$item"/. "$item/"
      done
      rm -rf "$TEMP_EXTRACT"
      TEMP_EXTRACT=""
    else
      echo "Extracting data..."
      cd /
      ${pkgs.borgbackup}/bin/borg extract --verbose --list "$REPO"::"$ARCHIVE" ${lib.concatStringsSep " " recoveryPlan.restoreItems}
    fi

    echo ""
    echo "Starting services..."
    for svc in ${lib.concatStringsSep " " recoveryPlan.startServices}; do
      systemctl start "$svc" || true
    done

    echo ""
    echo "========================================"
    echo "✓ Recovery complete: ${serviceName}"
    echo "========================================"
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
   
    set -euo pipefail
    export BORG_PASSPHRASE=$(cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

    TEMP_MOUNT=""
    TEMP_EXTRACT=""
    EXTRACT_TO_TEMP=false
    CLEANUP_MOUNT=false

    # cleanup function
    cleanup() {
      if [ "$CLEANUP_MOUNT" = true ] && [ -n "$TEMP_MOUNT" ] && [ -d "$TEMP_MOUNT" ]; then
        echo "Cleaning up remote mount..."
        if mountpoint -q "$TEMP_MOUNT" 2>/dev/null; then
          fusermount -u "$TEMP_MOUNT" 2>/dev/null || umount "$TEMP_MOUNT" 2>/dev/null || true
        fi
        rmdir "$TEMP_MOUNT" 2>/dev/null || true
      fi
      if [ -n "$TEMP_EXTRACT" ] && [ -d "$TEMP_EXTRACT" ]; then
        echo "Cleaning up temp extraction..."
        rm -rf "$TEMP_EXTRACT"
      fi
    }

    # register cleanup on exit
    trap cleanup EXIT INT TERM

    echo "========================================"
    echo "Recovery: ${serviceName}"
    echo "========================================"
    echo ""

    # repo source selection
    echo "Select repository source:"
    echo "  L) Local repository"
    echo "  R) Remote repository (Backblaze B2)"
    echo ""
    read -p "Source [L]: " repo_type
    repo_type=''${repo_type:-L}
    
    if [[ "$repo_type" =~ ^[Rr]$ ]]; then
      HOSTS=(${lib.concatStringsSep " " (builtins.attrNames configVars.hosts)})
      
      echo ""
      echo "Available hosts:"
      for i in "''${!HOSTS[@]}"; do
        if [ "''${HOSTS[$i]}" = "${config.networking.hostName}" ]; then
          echo "  $((i+1))) ''${HOSTS[$i]} (current host)"
        else
          echo "  $((i+1))) ''${HOSTS[$i]}"
        fi
      done
      echo ""
      
      read -p "Select host [1]: " host_num
      host_num=''${host_num:-1}
      
      if ! [[ "$host_num" =~ ^[0-9]+$ ]] || [ "$host_num" -lt 1 ] || [ "$host_num" -gt "''${#HOSTS[@]}" ]; then
        echo "Invalid selection"
        exit 1
      fi
      
      SOURCE_HOST="''${HOSTS[$((host_num-1))]}"
      echo "Selected: $SOURCE_HOST"
      
      # mount remote
      TEMP_MOUNT="/tmp/borg-mount-$$"
      mkdir -p "$TEMP_MOUNT"
      
      echo ""
      echo "Mounting remote backup from $SOURCE_HOST via Backblaze B2..."
      echo "This may take a few moments..."
      ${pkgs.rclone}/bin/rclone mount \
        --config "${rcloneConf}" \
        --vfs-cache-mode writes \
        --allow-other \
        --daemon \
        backblaze-b2:$SOURCE_HOST-backup-dcbond "$TEMP_MOUNT"
      
      # wait for mount to be ready
      sleep 5
      
      # verify mount succeeded
      if ! mountpoint -q "$TEMP_MOUNT"; then
        echo "ERROR: Failed to mount remote repository"
        exit 1
      fi
      
      REPO="$TEMP_MOUNT"
      CLEANUP_MOUNT=true
      EXTRACT_TO_TEMP=true
      echo "Remote repository mounted"
      
    else
      REPO="${config.backups.borgDir}/${config.networking.hostName}"
      
      # verify local repo exists
      if [ ! -d "$REPO" ]; then
        echo "ERROR: Local repository not found at $REPO"
        exit 1
      fi
      
      echo "Using local repository: $REPO"
    fi

    # archive selection
    echo ""
    echo "Fetching archives..."
    archives=$(${pkgs.borgbackup}/bin/borg list --short "$REPO")
    
    if [ -z "$archives" ]; then
      echo "ERROR: No archives found"
      exit 1
    fi
    
    echo ""
    echo "Available archives:"
    echo "$archives" | nl -w2 -s') '
    echo ""
    read -p "Select archive: " num
    
    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
      echo "Invalid selection"
      exit 1
    fi
    
    ARCHIVE=$(echo "$archives" | sed -n "''${num}p")
    
    if [ -z "$ARCHIVE" ]; then
      echo "Invalid selection"
      exit 1
    fi
    
    echo "Selected: $ARCHIVE"

    # extract data before bringing services down (if remote)
    if [ "$EXTRACT_TO_TEMP" = true ]; then
      echo ""
      echo "========================================"
      echo "Phase 1: downloading data"
      echo "========================================"
      
      TEMP_EXTRACT="/tmp/borg-extract-$$"
      mkdir -p "$TEMP_EXTRACT"
      
      echo ""
      echo "Extracting to /tmp..."
      
      cd "$TEMP_EXTRACT"
      if ! ${pkgs.borgbackup}/bin/borg extract --verbose --list "$REPO"::"$ARCHIVE" ${lib.concatStringsSep " " recoveryPlan.restoreItems}; then
        echo ""
        echo "ERROR: Extraction failed. No changes made to services."
        exit 1
      fi
      
      echo ""
      echo "✓ Data downloaded successfully"
      
      # unmount remote
      fusermount -u "$TEMP_MOUNT" 2>/dev/null || true
      rmdir "$TEMP_MOUNT" 2>/dev/null || true
      CLEANUP_MOUNT=false
    fi

    echo ""
    echo "========================================"
    echo "Phase 2: applying recovery"
    echo "========================================"
    echo ""
    echo "This will:"
    echo "  Stop: ${lib.concatStringsSep ", " recoveryPlan.stopServices}"
    echo "  Replace service data"
    ${lib.optionalString (dbType != null) ''
    echo "  Restore database"
    ''}
    echo ""
    read -p "Proceed? (y/N): " confirm
    if ! [[ "$confirm" =~ ^[Yy]$ ]]; then
      echo "Aborted. No changes made."
      exit 0
    fi

    ${preRestoreHook}

    echo ""
    echo "Stopping services..."
    for svc in ${lib.concatStringsSep " " recoveryPlan.stopServices}; do
      systemctl stop "$svc" || true
    done

    ${postSvcStopHook}

    # copy (if remote) or direct extract (if local) recovery data
    if [ "$EXTRACT_TO_TEMP" = true ]; then
      echo "Moving data to final location..."
      for item in ${lib.concatStringsSep " " recoveryPlan.restoreItems}; do
        if [ ! -e "$TEMP_EXTRACT$item" ]; then
          echo "ERROR: Extracted data not found at $TEMP_EXTRACT$item"
          exit 1
        fi
        # remove old data and copy restore directory from /tmp
        rm -rf "$item"
        mkdir -p "$(dirname "$item")"
        cp -av "$TEMP_EXTRACT$item" "$item"
      done
      rm -rf "$TEMP_EXTRACT"
      TEMP_EXTRACT=""
    else
      echo "Extracting data..."
      cd /
      ${pkgs.borgbackup}/bin/borg extract --verbose --list "$REPO"::"$ARCHIVE" ${lib.concatStringsSep " " recoveryPlan.restoreItems}
    fi

    # ensure we're in a valid directory for database operations
    cd /

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

    ${preSvcStartHook}

    echo ""
    echo "Starting services..."
    for svc in ${lib.concatStringsSep " " recoveryPlan.startServices}; do
      systemctl start "$svc" || true
    done

    ${postRestoreHook}

    echo ""
    echo "========================================"
    echo "✓ Recovery complete: ${serviceName}"
    echo "========================================"
  '';

in

{

  options.backups = {
    borgDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/borgbackup"; # default, override with different directory in host-specific configuration.nix
      description = "path to the directory for borg backups";
    };
    startTime = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 03:35:00"; # default everyday at 3:35am, override with alternate time in host-specific configuration.nix
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
        chrisEmailPasswd = {};
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
      initLocalRepoScript
      cloudBackupScript
      backupFailureEmailScript
      backupSuccessEmailScript
      backupFailureWebhookScript
      backupSuccessWebhookScript
      inspectLocalBackupsScript
      inspectRemoteBackupsScript
      rclone
      fuse # needed for rclone mount
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
        doInit = false; # do not run borg init if backup directory does not already contain the repository, must init manually on new machine
        failOnWarnings = false;
        extraCreateArgs = [
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
        
        # if local backup fails for any reason, send failure email, cloudBackup.service is NOT triggered
          # e.g. - 
          # - if local borg repo directory doesn't exist, backup fails and failure email sent
          # - if local borg repo directory is empty, will not automatically init, backup fails and failure email sent
          # - if borg cache issues while attempting local backup, backup fails and failure email sent
          # - if service wind-down or spin-up fails, backup fails and failure email sent
        # if local backup succeeds, trigger cloudBackup.service
        "borgbackup-job-${config.networking.hostName}" = {
          wantedBy = lib.mkForce []; # do not automatically start service on system rebuild/reboot
          unitConfig = {
            OnSuccess = "cloudBackup.service";
            OnFailure = "backupFailureEmail.service backupFailureWebhook.service";
          };
        };

        # if local backup had succeeded but corrupted repo, cloudBackup.service borg check --verify-data will fail and sync averted, failure email sent
        # if rclone sync fails, failure email sent
        "cloudBackup" = {
          description = "borg local repository validation and rclone backup to backblaze cloud storage";
          wantedBy = lib.mkForce [];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${cloudBackupScript}/bin/cloudBackup";
            EnvironmentFile = "${rcloneConf}";
          };
          unitConfig = {
            OnSuccess = "backupSuccessEmail.service backupSuccessWebhook.service";
            OnFailure = "backupFailureEmail.service backupFailureWebhook.service";
          };
        };

        "backupSuccessEmail" = {
          description = "send backup success notification";
          wantedBy = lib.mkForce [];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${backupSuccessEmailScript}/bin/backupSuccessEmail";
          };
        };

        "backupFailureEmail" = {
          description = "send backup failure notification";
          wantedBy = lib.mkForce [];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${backupFailureEmailScript}/bin/backupFailureEmail";
          };
        };

        "backupSuccessWebhook" = {
          description = "send backup success webhook notification to matrix";
          wantedBy = lib.mkForce [];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${backupSuccessWebhookScript}/bin/backupSuccessWebhook";
          };
        };

        "backupFailureWebhook" = {
          description = "send backup failure webhook notification to matrix";
          wantedBy = lib.mkForce [];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${backupFailureWebhookScript}/bin/backupFailureWebhook";
          };
        };
        
      };
    };
    
  };

}