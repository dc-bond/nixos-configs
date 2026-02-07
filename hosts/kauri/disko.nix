{
  inputs,
  config,
  pkgs,
  ...
}: 

{

  imports = [ inputs.disko.nixosModules.disko ];

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                settings = {
                  allowDiscards = false;
                };
                passwordFile = "/tmp/crypt-passwd.txt"; # interactive login
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/home" = { # to be deprecated on next fresh installation
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    #"/snapshots" = { # to be implemented on next fresh installation
                    #  mountpoint = "/snapshots";
                    #  mountOptions = [ "compress=zstd" "noatime" ];
                    #};
                    "/swap" = {
                      mountpoint = "/swap";
                      swap.swapfile.size = "8G"; # 0.5x RAM - adequate OOM protection without hibernation
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  services = {
    # weekly btrfs scrub for data integrity
    btrfs.autoScrub = {
      enable = true;
      interval = "Sun *-*-* 04:00:00";
      fileSystems = [ "/dev/mapper/crypted" ];
    };

    # requires: /snapshots subvolume (uncomment on next fresh installation)
    #btrbk.instances = {
    #  # automatic hourly snapshots for manual copy/paste "oops I deleted that file" recoveries
    #  hourly = {
    #    onCalendar = "hourly";
    #    settings = {
    #      timestamp_format = "long";
    #      snapshot_preserve_min = "2d"; # keep all snapshots for 2 days (48 snapshots)
    #      volume."/" = {
    #        subvolume."root" = {
    #          snapshot_dir = "/snapshots";
    #          snapshot_name = "hourly-root";
    #        };
    #      };
    #    };
    #  };
    #
    #  # recovery snapshot (for both borg backups and rebuild rollbacks)
    #  recovery = {
    #    onCalendar = null; # manual trigger only (via backup preHook and rebuild-snapshot command)
    #    settings = {
    #      timestamp_format = "long";
    #      snapshot_preserve_min = "latest"; # keep only the most recent recovery snapshot
    #      volume."/" = {
    #        subvolume."root" = {
    #          snapshot_dir = "/snapshots";
    #          snapshot_name = "recovery-root";
    #        };
    #      };
    #    };
    #  };
    #};
  };

  # requires: /snapshots subvolume (uncomment on next fresh installation)
  #systemd.services.btrbk-recovery.serviceConfig.ExecStartPre = [
  #  "+${pkgs.writeShellScript "save-nixos-generation" ''
  #    ${pkgs.coreutils}/bin/readlink /nix/var/nix/profiles/system \
  #      | ${pkgs.gnused}/bin/sed 's/system-\([0-9]*\)-link/\1/' \
  #      > /.nixos-generation
  #  ''}"
  #];

  # requires: /snapshots subvolume (uncomment on next fresh installation)
  #environment.systemPackages = [
  #  # unified snapshot recovery: restore from backblaze or local disk
  #  (pkgs.writeShellScriptBin "recoverSnap" ''
  #    #!/usr/bin/env bash
  #    set -euo pipefail
  #
  #    # check for root
  #    if [ "$(id -u)" -ne 0 ]; then
  #      echo "ERROR: This script must be run as root"
  #      echo "Usage: sudo recoverSnap"
  #      exit 1
  #    fi
  #
  #    export BORG_PASSPHRASE=$(cat /run/secrets/borgCryptPasswd)
  #    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
  #
  #    TEMP_MOUNT=""
  #    TEMP_EXTRACT=""
  #    BTRFS_ROOT=""
  #
  #    # cleanup function
  #    cleanup() {
  #      echo ""
  #      echo "Cleaning up..."
  #      if [ -n "$TEMP_MOUNT" ] && [ -d "$TEMP_MOUNT" ]; then
  #        if mountpoint -q "$TEMP_MOUNT" 2>/dev/null; then
  #          echo "  Unmounting remote backup..."
  #          fusermount -u "$TEMP_MOUNT" 2>/dev/null || umount "$TEMP_MOUNT" 2>/dev/null || true
  #        fi
  #        rmdir "$TEMP_MOUNT" 2>/dev/null || true
  #      fi
  #      if [ -n "$TEMP_EXTRACT" ] && [ -d "$TEMP_EXTRACT" ]; then
  #        echo "  Removing temp extraction directory..."
  #        rm -rf "$TEMP_EXTRACT"
  #      fi
  #      if [ -n "$BTRFS_ROOT" ] && [ -d "$BTRFS_ROOT" ]; then
  #        if mountpoint -q "$BTRFS_ROOT" 2>/dev/null; then
  #          echo "  Unmounting btrfs root..."
  #          ${pkgs.util-linux}/bin/umount "$BTRFS_ROOT" 2>/dev/null || true
  #        fi
  #        rmdir "$BTRFS_ROOT" 2>/dev/null || true
  #      fi
  #      echo "  Cleanup complete."
  #    }
  #
  #    trap cleanup EXIT INT TERM
  #
  #    echo "========================================"
  #    echo "/ Recovery"
  #    echo "========================================"
  #    echo ""
  #
  #    # check if local recovery snapshot exists
  #    RECOVERY_SNAPSHOT=$(ls -dt /snapshots/recovery-root.* 2>/dev/null | head -1 || true)
  #
  #    if [ -n "$RECOVERY_SNAPSHOT" ]; then
  #      # SCENARIO A: Local snapshot exists (system rollback)
  #      SNAPSHOT_NAME=$(basename "$RECOVERY_SNAPSHOT")
  #      TIMESTAMP=''${SNAPSHOT_NAME#recovery-root.}
  #
  #      echo "Found local recovery snapshot: $TIMESTAMP"
  #      echo ""
  #      echo "This will restore / from the local snapshot."
  #      echo ""
  #      read -p "Continue? (y/N): " confirm
  #
  #      if ! [[ "$confirm" =~ ^[Yy]$ ]]; then
  #        echo "Cancelled."
  #        exit 0
  #      fi
  #
  #      echo ""
  #      echo "Restoring / from local snapshot..."
  #
  #      echo "Mounting btrfs root..."
  #      BTRFS_ROOT=$(mktemp -d)
  #      ${pkgs.util-linux}/bin/mount -t btrfs -o subvolid=5 /dev/mapper/crypted "$BTRFS_ROOT"
  #      echo "✓ Btrfs root mounted at $BTRFS_ROOT"
  #
  #      echo "Renaming current root subvolume..."
  #      ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$BTRFS_ROOT/root-old" 2>/dev/null || true
  #      mv "$BTRFS_ROOT/root" "$BTRFS_ROOT/root-old"
  #      echo "Creating snapshot from $SNAPSHOT_NAME..."
  #      ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot "$BTRFS_ROOT/snapshots/$SNAPSHOT_NAME" "$BTRFS_ROOT/root"
  #
  #      echo "Unmounting btrfs root..."
  #      ${pkgs.util-linux}/bin/umount "$BTRFS_ROOT"
  #      rmdir "$BTRFS_ROOT"
  #      BTRFS_ROOT=""
  #      echo "✓ Btrfs root unmounted and cleaned up"
  #
  #      echo "✓ / will be restored on reboot"
  #      echo ""
  #      echo "NOTE: After reboot, clean up the old root subvolume:"
  #      echo "  BTRFS_ROOT=\$(mktemp -d)"
  #      echo "  sudo mount -t btrfs -o subvolid=5 /dev/mapper/crypted \$BTRFS_ROOT"
  #      echo "  sudo btrfs subvolume delete \$BTRFS_ROOT/root-old"
  #      echo "  sudo umount \$BTRFS_ROOT && rmdir \$BTRFS_ROOT"
  #
  #      # nixos generation rollback (only applies to local rollback where nix store is intact)
  #      echo ""
  #      if [ -f /.nixos-generation ]; then
  #        TARGET_GEN=$(cat /.nixos-generation)
  #        CURRENT_GEN=$(readlink /nix/var/nix/profiles/system | sed 's/system-\([0-9]*\)-link/\1/')
  #
  #        echo "Snapshot was taken during NixOS generation $TARGET_GEN"
  #        echo "Current NixOS generation: $CURRENT_GEN"
  #
  #        if [ "$TARGET_GEN" = "$CURRENT_GEN" ]; then
  #          echo "Already on the correct generation, no rollback needed."
  #        elif [ -e "/nix/var/nix/profiles/system-''${TARGET_GEN}-link" ]; then
  #          read -p "Switch to generation $TARGET_GEN? (y/N): " rollback
  #
  #          if [[ "$rollback" =~ ^[Yy]$ ]]; then
  #            echo ""
  #            echo "Switching to NixOS generation $TARGET_GEN..."
  #            ${pkgs.nix}/bin/nix-env --switch-generation "$TARGET_GEN" --profile /nix/var/nix/profiles/system
  #            /nix/var/nix/profiles/system/bin/switch-to-configuration boot
  #            echo "✓ Switched to generation $TARGET_GEN"
  #          fi
  #        else
  #          echo "WARNING: Generation $TARGET_GEN no longer exists (garbage collected?)"
  #          echo ""
  #          echo "Available generations:"
  #          ${pkgs.nix}/bin/nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -5
  #          echo ""
  #          read -p "Rollback one generation instead? (y/N): " rollback
  #
  #          if [[ "$rollback" =~ ^[Yy]$ ]]; then
  #            echo ""
  #            echo "Rolling back NixOS generation..."
  #            ${pkgs.nix}/bin/nix-env --rollback --profile /nix/var/nix/profiles/system
  #            /nix/var/nix/profiles/system/bin/switch-to-configuration boot
  #            echo "✓ Generation rolled back"
  #          fi
  #        fi
  #      else
  #        echo "No generation info found in snapshot, skipping generation rollback."
  #      fi
  #
  #    else
  #      # SCENARIO B: No local snapshot (disaster recovery)
  #      echo "No local snapshot found - disaster recovery mode"
  #      echo ""
  #      echo "This will restore / from the most recent Backblaze backup."
  #      echo ""
  #      read -p "Continue? (y/N): " confirm
  #
  #      if ! [[ "$confirm" =~ ^[Yy]$ ]]; then
  #        echo "Cancelled."
  #        exit 0
  #      fi
  #
  #      echo ""
  #      echo "Mounting remote backup via Backblaze B2..."
  #      echo "This may take a few moments..."
  #
  #      TEMP_MOUNT="/tmp/borg-mount-$$"
  #      mkdir -p "$TEMP_MOUNT"
  #
  #      ${pkgs.rclone}/bin/rclone mount \
  #        --config /run/secrets/rendered/rclone.conf \
  #        --vfs-cache-mode writes \
  #        --allow-other \
  #        --daemon \
  #        backblaze-b2:${config.networking.hostName}-backup-dcbond "$TEMP_MOUNT"
  #
  #      sleep 5
  #
  #      if ! mountpoint -q "$TEMP_MOUNT"; then
  #        echo "ERROR: Failed to mount remote repository"
  #        exit 1
  #      fi
  #
  #      echo "✓ Remote repository mounted"
  #
  #      # get most recent archive (no user selection)
  #      echo ""
  #      echo "Fetching most recent backup..."
  #      ARCHIVE=$(${pkgs.borgbackup}/bin/borg list --short "$TEMP_MOUNT" | tail -1)
  #
  #      if [ -z "$ARCHIVE" ]; then
  #        echo "ERROR: No archives found in remote repository"
  #        exit 1
  #      fi
  #
  #      echo "Using archive: $ARCHIVE"
  #
  #      # find recovery snapshot in archive
  #      SNAPSHOT_PATH=$(${pkgs.borgbackup}/bin/borg list --short "$TEMP_MOUNT"::"$ARCHIVE" | grep "^snapshots/recovery-root" | head -1 || true)
  #
  #      if [ -z "$SNAPSHOT_PATH" ]; then
  #        echo "ERROR: No recovery-root snapshot found in archive"
  #        echo ""
  #        echo "Archive contains:"
  #        ${pkgs.borgbackup}/bin/borg list --short "$TEMP_MOUNT"::"$ARCHIVE" | head -20
  #        exit 1
  #      fi
  #
  #      echo "Found snapshot: $SNAPSHOT_PATH"
  #
  #      # mount btrfs root early to extract to disk instead of tmpfs
  #      echo ""
  #      echo "Mounting btrfs root..."
  #      BTRFS_ROOT=$(mktemp -d)
  #      ${pkgs.util-linux}/bin/mount -t btrfs -o subvolid=5 /dev/mapper/crypted "$BTRFS_ROOT"
  #
  #      # create temp extraction directory on disk
  #      TEMP_EXTRACT="$BTRFS_ROOT/tmp-borg-extract-$$"
  #      mkdir -p "$TEMP_EXTRACT"
  #
  #      # extract snapshot to disk
  #      echo ""
  #      echo "Streaming snapshot from B2 to local disk..."
  #      cd "$TEMP_EXTRACT"
  #      if ! ${pkgs.borgbackup}/bin/borg extract --verbose --list "$TEMP_MOUNT"::"$ARCHIVE" "$SNAPSHOT_PATH"; then
  #        echo "ERROR: Stream extraction failed"
  #        exit 1
  #      fi
  #
  #      echo "✓ Snapshot downloaded"
  #
  #      # unmount remote
  #      fusermount -u "$TEMP_MOUNT" 2>/dev/null || true
  #      rmdir "$TEMP_MOUNT" 2>/dev/null || true
  #      TEMP_MOUNT=""
  #
  #      # recreate / and restore
  #      echo ""
  #      echo "Restoring /..."
  #
  #      # delete old root and create new subvolume
  #      ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$BTRFS_ROOT/root" 2>/dev/null || true
  #      ${pkgs.btrfs-progs}/bin/btrfs subvolume create "$BTRFS_ROOT/root"
  #
  #      # copy extracted files to new root subvolume
  #      ${pkgs.rsync}/bin/rsync -av "$TEMP_EXTRACT/$SNAPSHOT_PATH/" "$BTRFS_ROOT/root/"
  #
  #      # cleanup temp extraction
  #      echo "Removing temp extraction directory..."
  #      cd /
  #      rm -rf "$TEMP_EXTRACT"
  #      TEMP_EXTRACT=""
  #
  #      echo "Unmounting btrfs root..."
  #      ${pkgs.util-linux}/bin/umount "$BTRFS_ROOT"
  #      rmdir "$BTRFS_ROOT"
  #      BTRFS_ROOT=""
  #      echo "✓ Btrfs root unmounted and cleaned up"
  #
  #      echo "✓ / restored successfully"
  #    fi
  #
  #    # reboot
  #    echo ""
  #    echo "========================================"
  #    echo "Recovery complete. Rebooting in 3 seconds..."
  #    echo "========================================"
  #    sleep 3
  #    reboot
  #  '')
  #];

}