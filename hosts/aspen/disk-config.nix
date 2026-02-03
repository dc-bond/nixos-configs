{
  inputs,
  config,
  configVars,
  pkgs,
  ...
}: 

{

  imports = [
    inputs.disko.nixosModules.disko
  ];

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_960_EVO_250GB_S3ESNX0J831623T"; # Samsung 960 EVO 256GB M.2 SSD
        #device = "/dev/nvme0n1"; # hardware path
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
  
            root = {
              size = "100%";
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
                    swap.swapfile.size = "8G"; # 0.25x RAM - adequate OOM protection for well-provisioned server
                  };
                };
              };
            };
  
          };   
        };
      };
    };
  };

  bulkStorage.path = "/storage"; # Western Digital 4TB SATA HDD ata-WDC_WD40EFRX-68N32N0_WD-WCC7K4RU947F

  fileSystems."/storage" = {
    device = "/dev/disk/by-uuid/2dbedc67-9a6b-477f-a3b4-75116994d1cb";
    fsType = "ext4";
    options = [ "defaults" ];
  };

  services = {
    # weekly btrfs scrub for data integrity
    btrfs.autoScrub = {
      enable = true;
      interval = "Sun *-*-* 04:00:00";
      fileSystems = [ "/dev/disk/by-id/nvme-Samsung_SSD_960_EVO_250GB_S3ESNX0J831623T-part2" ];
    };

    # recovery snapshot (for backup disaster recovery - uncomment to enable)
    # requires: /snapshots subvolume (add to disko config on next fresh install)
    # usage: triggered automatically by nightly backup preHook
    # adds full system snapshot to borg backup alongside individual service directories
    #btrbk.instances.recovery = {
    #  onCalendar = null; # manual trigger only (via backup preHook)
    #  settings = {
    #    timestamp_format = "long";
    #    snapshot_preserve_min = "latest"; # keep only the most recent recovery snapshot
    #    snapshot_create = "always";
    #    volume."/" = {
    #      subvolume."root" = {
    #        snapshot_dir = "/snapshots";
    #        snapshot_name = "recovery-root";
    #      };
    #    };
    #  };
    #};
  };

  # environment.systemPackages = [
  #   # create snapshot of root
  #   (pkgs.writeShellScriptBin "snapshot-create" ''
  #     #!/usr/bin/env bash
  #     set -euo pipefail
  #     echo "Creating manual snapshot..."
  #     TIMESTAMP=$(date +%Y.%m.%d.%H.%M.%S)
  #     sudo ${pkgs.btrbk}/bin/btrbk snapshot /
  #     echo "Snapshot created: root-$TIMESTAMP"
  #   '')
  #
  #   # rollback system to a previous snapshot state
  #   (pkgs.writeShellScriptBin "rollback-system" ''
  #     #!/usr/bin/env bash
  #     set -euo pipefail
  #
  #     # ─────────────────────────────────────────────────────────────────────
  #     # STEP 1: List available snapshots
  #     # ─────────────────────────────────────────────────────────────────────
  #
  #     echo "Available btrbk snapshots:"
  #     echo ""
  #
  #     # List snapshots directly from the snapshots directory
  #     mapfile -t snapshots < <(ls -1 /snapshots/ 2>/dev/null | grep "^root-" | sort -r)
  #
  #     if [ ''${#snapshots[@]} -eq 0 ]; then
  #       echo "No snapshots found"
  #       echo "Use 'snapshot-create' to create a rollback point"
  #       exit 1
  #     fi
  #
  #     for i in "''${!snapshots[@]}"; do
  #       snapshot_name="''${snapshots[$i]}"
  #       # Extract timestamp from name (format: root-YYYY.MM.DD.HH.MM.SS)
  #       timestamp=''${snapshot_name#root-}
  #       # Timestamp already in readable format, display as-is
  #       echo "  $((i+1)). $timestamp"
  #     done
  #
  #     # ─────────────────────────────────────────────────────────────────────
  #     # STEP 2: User selects which snapshot to restore
  #     # ─────────────────────────────────────────────────────────────────────
  #
  #     echo ""
  #     read -p "Select rollback point (1-''${#snapshots[@]}): " choice
  #
  #     if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ''${#snapshots[@]} ]; then
  #       echo "Invalid selection"
  #       exit 1
  #     fi
  #
  #     SNAPSHOT_NAME="''${snapshots[$((choice-1))]}"
  #
  #     # ─────────────────────────────────────────────────────────────────────
  #     # STEP 3: Confirm and execute rollback
  #     # ─────────────────────────────────────────────────────────────────────
  #
  #     echo ""
  #     echo "WARNING: Complete System Rollback"
  #     echo ""
  #     echo "Rolling back to: $SNAPSHOT_NAME"
  #     echo ""
  #     read -p "Continue? (yes/no): " CONFIRM
  #
  #     if [ "$CONFIRM" != "yes" ]; then
  #       echo "Cancelled"
  #       exit 0
  #     fi
  #
  #     echo ""
  #     echo "Rolling back root..."
  #
  #     # Mount BTRFS root temporarily for rollback operation
  #     BTRFS_ROOT=$(mktemp -d)
  #     sudo ${pkgs.util-linux}/bin/mount -t btrfs -o subvolid=5 /dev/disk/by-id/nvme-Samsung_SSD_960_EVO_250GB_S3ESNX0J831623T-part2 "$BTRFS_ROOT"
  #
  #     # Delete current root and replace with snapshot
  #     sudo ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$BTRFS_ROOT/root"
  #     sudo ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot "$BTRFS_ROOT/snapshots/$SNAPSHOT_NAME" "$BTRFS_ROOT/root"
  #
  #     # Cleanup temp mount
  #     sudo ${pkgs.util-linux}/bin/umount "$BTRFS_ROOT"
  #     rmdir "$BTRFS_ROOT"
  #
  #     echo "Rolling back NixOS generation..."
  #     sudo nixos-rebuild switch --rollback
  #
  #     echo ""
  #     echo "Rebooting in 2 seconds..."
  #     sleep 2
  #     sudo reboot
  #   '')
  # ];

}