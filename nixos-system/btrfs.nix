{
  config,
  lib,
  pkgs,
  configVars,
  ...
}:

let

  cfg = config.btrfs;
  hostData = configVars.hosts.${config.networking.hostName};
  # use mountpoint for encrypted systems (btrfs scrub works on /dev/mapper/crypted via mountpoint)
  # use raw partition for unencrypted systems
  scrubDevice = if (hostData.hardware.diskEncryption or false)
    then "/persist"
    else "${hostData.hardware.disk0}-part2";
  btrfsRootDevice = config.fileSystems."/persist".device; # only evaluated when cfg.snapshots = true

in

{

  options.btrfs.snapshots = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable btrfs snapshots and recovery tooling (impermanence workstations only)";
  };

  config = {

    services.btrfs.autoScrub = {
      enable = true;
      interval = "Sun *-*-* 04:00:00"; # weekly sunday at 4am
      fileSystems = [ scrubDevice ];
    };

    services.btrbk.instances = lib.mkIf cfg.snapshots {

      # hourly snapshots for quick "oops I deleted that" recoveries
      hourly = {
        onCalendar = "hourly";
        settings = {
          timestamp_format = "long";
          snapshot_preserve_min = "1d"; # keep the last 24 hourly snapshots
          volume."/" = {
            subvolume.persist = {
              snapshot_dir = "/snapshots";
              snapshot_name = "hourly-persist";
            };
          };
        };
      };

      # recovery snapshots (for backups and rebuild rollbacks)
      recovery = {
        onCalendar = null; # manual trigger only (via backup preHook and rebuild-snapshot)
        settings = {
          timestamp_format = "long";
          snapshot_preserve_min = "latest"; # keep only the most recent recovery snapshot
          volume."/" = {
            subvolume.persist = {
              snapshot_dir = "/snapshots";
              snapshot_name = "recovery-persist";
            };
          };
        };
      };

    };

    # save NixOS generation number before recovery snapshot
    systemd.services.btrbk-recovery.serviceConfig.ExecStartPre = lib.mkIf cfg.snapshots [
      "+${pkgs.writeShellScript "save-nixos-generation" ''
        ${pkgs.coreutils}/bin/readlink /nix/var/nix/profiles/system \
          | ${pkgs.gnused}/bin/sed 's/system-\([0-9]*\)-link/\1/' \
          > /persist/.nixos-generation
      ''}"
    ];

    backups = lib.mkIf cfg.snapshots {
      serviceHooks.preHook = lib.mkOrder 2000 [
        "systemctl start btrbk-recovery.service"
      ];
      standaloneData = [ "/snapshots" ];
      exclude = [ "/snapshots/hourly-persist.*" ];
    };

    # unified snapshot recovery: restore from backblaze or local disk
    environment.systemPackages = lib.mkIf cfg.snapshots [ (pkgs.writeShellScriptBin "recoverSnap" ''
      #!/usr/bin/env bash
      set -euo pipefail

      if [ "$(id -u)" -ne 0 ]; then
        echo "ERROR: This script must be run as root"
        echo "Usage: sudo recoverSnap"
        exit 1
      fi

      export BORG_PASSPHRASE=$(cat /run/secrets/borgCryptPasswd)
      export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

      TEMP_MOUNT=""
      TEMP_EXTRACT=""
      BTRFS_ROOT=""

      cleanup() {
        echo ""
        echo "Cleaning up..."
        if [ -n "$TEMP_MOUNT" ] && [ -d "$TEMP_MOUNT" ]; then
          if mountpoint -q "$TEMP_MOUNT" 2>/dev/null; then
            echo "  Unmounting remote backup..."
            fusermount -u "$TEMP_MOUNT" 2>/dev/null || umount "$TEMP_MOUNT" 2>/dev/null || true
          fi
          rmdir "$TEMP_MOUNT" 2>/dev/null || true
        fi
        if [ -n "$TEMP_EXTRACT" ] && [ -d "$TEMP_EXTRACT" ]; then
          echo "  Removing temp extraction directory..."
          rm -rf "$TEMP_EXTRACT"
        fi
        if [ -n "$BTRFS_ROOT" ] && [ -d "$BTRFS_ROOT" ]; then
          if mountpoint -q "$BTRFS_ROOT" 2>/dev/null; then
            echo "  Unmounting btrfs root..."
            ${pkgs.util-linux}/bin/umount "$BTRFS_ROOT" 2>/dev/null || true
          fi
          rmdir "$BTRFS_ROOT" 2>/dev/null || true
        fi
        echo "Cleanup complete."
      }

      trap cleanup EXIT INT TERM

      echo "========================================"
      echo "/persist Recovery"
      echo "========================================"
      echo ""

      RECOVERY_SNAPSHOT=$(ls -dt /snapshots/recovery-persist.* 2>/dev/null | head -1 || true)

      if [ -n "$RECOVERY_SNAPSHOT" ]; then

        # SCENARIO A: Local snapshot exists (system rollback)

        SNAPSHOT_NAME=$(basename "$RECOVERY_SNAPSHOT")
        TIMESTAMP=''${SNAPSHOT_NAME#recovery-persist.}

        echo "Found local recovery snapshot: $TIMESTAMP"
        echo ""
        echo "This will restore /persist from the local snapshot."
        echo ""
        read -p "Continue? (y/N): " confirm

        if ! [[ "$confirm" =~ ^[Yy]$ ]]; then
          echo "Cancelled."
          exit 0
        fi

        echo ""
        echo "Restoring /persist from local snapshot..."

        echo "Mounting btrfs root..."
        BTRFS_ROOT=$(mktemp -d)
        ${pkgs.util-linux}/bin/mount -t btrfs -o subvolid=5 ${btrfsRootDevice} "$BTRFS_ROOT"
        echo "✓ Btrfs root mounted at $BTRFS_ROOT"

        echo "Deleting current /persist subvolume..."
        ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$BTRFS_ROOT/persist"
        echo "Creating snapshot from $SNAPSHOT_NAME..."
        ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot "$BTRFS_ROOT/snapshots/$SNAPSHOT_NAME" "$BTRFS_ROOT/persist"

        echo "Unmounting btrfs root..."
        ${pkgs.util-linux}/bin/umount "$BTRFS_ROOT"
        rmdir "$BTRFS_ROOT"
        BTRFS_ROOT=""
        echo "✓ Btrfs root unmounted"

        echo "Remounting /persist to reflect restored subvolume..."
        ${pkgs.util-linux}/bin/umount /persist
        ${pkgs.util-linux}/bin/mount /persist
        echo "✓ /persist restored successfully"

        echo ""
        if [ -f /persist/.nixos-generation ]; then
          TARGET_GEN=$(cat /persist/.nixos-generation)
          CURRENT_GEN=$(readlink /nix/var/nix/profiles/system | sed 's/system-\([0-9]*\)-link/\1/')

          echo "Snapshot was taken during NixOS generation $TARGET_GEN"
          echo "Current NixOS generation: $CURRENT_GEN"

          if [ "$TARGET_GEN" = "$CURRENT_GEN" ]; then
            echo "Already on the correct generation, no rollback needed."
          elif [ -e "/nix/var/nix/profiles/system-''${TARGET_GEN}-link" ]; then
            read -p "Switch to generation $TARGET_GEN? (y/N): " rollback

            if [[ "$rollback" =~ ^[Yy]$ ]]; then
              echo ""
              echo "Switching to NixOS generation $TARGET_GEN..."
              ${pkgs.nix}/bin/nix-env --switch-generation "$TARGET_GEN" --profile /nix/var/nix/profiles/system
              /nix/var/nix/profiles/system/bin/switch-to-configuration boot
              echo "✓ Switched to generation $TARGET_GEN"
            fi
          else
            echo "WARNING: Generation $TARGET_GEN no longer exists (garbage collected?)"
            echo ""
            echo "Available generations:"
            ${pkgs.nix}/bin/nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -5
            echo ""
            read -p "Rollback one generation instead? (y/N): " rollback

            if [[ "$rollback" =~ ^[Yy]$ ]]; then
              echo ""
              echo "Rolling back NixOS generation..."
              ${pkgs.nix}/bin/nix-env --rollback --profile /nix/var/nix/profiles/system
              /nix/var/nix/profiles/system/bin/switch-to-configuration boot
              echo "✓ Generation rolled back"
            fi
          fi
        else
          echo "No generation info found in snapshot, skipping generation rollback."
        fi

      else

        # SCENARIO B: No local snapshot (disaster recovery)

        echo "No local snapshot found - disaster recovery mode"
        echo ""
        echo "This will restore /persist from the most recent Backblaze backup."
        echo ""
        read -p "Continue? (y/N): " confirm

        if ! [[ "$confirm" =~ ^[Yy]$ ]]; then
          echo "Cancelled."
          exit 0
        fi

        echo ""
        echo "Mounting remote backup via Backblaze B2..."
        echo "This may take a few moments..."

        TEMP_MOUNT="/tmp/borg-mount-$$"
        mkdir -p "$TEMP_MOUNT"

        ${pkgs.rclone}/bin/rclone mount \
          --config /run/secrets/rendered/rclone.conf \
          --vfs-cache-mode writes \
          --allow-other \
          --daemon \
          backblaze-b2:${config.networking.hostName}-backup-dcbond "$TEMP_MOUNT"

        sleep 5

        if ! mountpoint -q "$TEMP_MOUNT"; then
          echo "ERROR: Failed to mount remote repository"
          exit 1
        fi

        echo "✓ Remote repository mounted"

        echo ""
        echo "Fetching most recent backup..."
        ARCHIVE=$(${pkgs.borgbackup}/bin/borg list --short "$TEMP_MOUNT" | tail -1)

        if [ -z "$ARCHIVE" ]; then
          echo "ERROR: No archives found in remote repository"
          exit 1
        fi

        echo "Using archive: $ARCHIVE"

        SNAPSHOT_PATH=$(${pkgs.borgbackup}/bin/borg list --short "$TEMP_MOUNT"::"$ARCHIVE" | grep "^snapshots/recovery-persist" | head -1 || true)

        if [ -z "$SNAPSHOT_PATH" ]; then
          echo "ERROR: No recovery-persist snapshot found in archive"
          echo ""
          echo "Archive contains:"
          ${pkgs.borgbackup}/bin/borg list --short "$TEMP_MOUNT"::"$ARCHIVE" | head -20
          exit 1
        fi

        echo "Found snapshot: $SNAPSHOT_PATH"

        # mount btrfs root early to extract to disk instead of tmpfs
        echo ""
        echo "Mounting btrfs root..."
        BTRFS_ROOT=$(mktemp -d)
        ${pkgs.util-linux}/bin/mount -t btrfs -o subvolid=5 ${btrfsRootDevice} "$BTRFS_ROOT"

        TEMP_EXTRACT="$BTRFS_ROOT/tmp-borg-extract-$$"
        mkdir -p "$TEMP_EXTRACT"

        echo ""
        echo "Streaming snapshot from B2 to local disk..."
        cd "$TEMP_EXTRACT"
        if ! ${pkgs.borgbackup}/bin/borg extract --verbose --list "$TEMP_MOUNT"::"$ARCHIVE" "$SNAPSHOT_PATH"; then
          echo "ERROR: Stream extraction failed"
          exit 1
        fi

        echo "✓ Snapshot downloaded"

        fusermount -u "$TEMP_MOUNT" 2>/dev/null || true
        rmdir "$TEMP_MOUNT" 2>/dev/null || true
        TEMP_MOUNT=""

        echo ""
        echo "Restoring /persist..."
        ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$BTRFS_ROOT/persist" 2>/dev/null || true
        ${pkgs.btrfs-progs}/bin/btrfs subvolume create "$BTRFS_ROOT/persist"

        ${pkgs.rsync}/bin/rsync -av "$TEMP_EXTRACT/$SNAPSHOT_PATH/" "$BTRFS_ROOT/persist/"

        echo "Removing temp extraction directory..."
        cd /
        rm -rf "$TEMP_EXTRACT"
        TEMP_EXTRACT=""

        echo "Unmounting btrfs root..."
        ${pkgs.util-linux}/bin/umount "$BTRFS_ROOT"
        rmdir "$BTRFS_ROOT"
        BTRFS_ROOT=""
        echo "✓ Btrfs root unmounted"

        echo "Remounting /persist to reflect restored subvolume..."
        ${pkgs.util-linux}/bin/umount /persist
        ${pkgs.util-linux}/bin/mount /persist
        echo "✓ /persist restored successfully"

      fi

      echo ""
      echo "========================================"
      echo "Recovery complete. Rebooting in 3 seconds..."
      echo "========================================"
      sleep 3
      reboot
    '') ];

  };

}