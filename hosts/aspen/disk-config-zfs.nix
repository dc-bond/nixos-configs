{
  inputs,
  config,
  ...
}:

{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  disko.devices = {
    disk = {
      # ============================================
      # Boot/System NVMe (UNCHANGED)
      # ============================================
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
                  "/home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/swap" = {
                    mountpoint = "/swap";
                    swap.swapfile.size = "16G";
                  };
                };
              };
            };

          };
        };
      };

      # ============================================
      # Data Pool HDDs (2x 12TB WD Gold RAID1)
      # ============================================
      # TODO: Replace device paths with actual disk IDs from:
      #       ls -la /dev/disk/by-id/ | grep WDC_WD122KRYZ

      data-hdd1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD122KRYZ-XXXXX";  # REPLACE WITH ACTUAL ID
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "storage";
              };
            };
          };
        };
      };

      data-hdd2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD122KRYZ-YYYYY";  # REPLACE WITH ACTUAL ID
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "storage";
              };
            };
          };
        };
      };
    };

    # ============================================
    # ZFS Pool Definition
    # ============================================
    zpool = {
      storage = {
        type = "zpool";
        mode = "mirror";
        options = {
          ashift = "12";  # 4K sector size (optimal for modern HDDs)
        };
        rootFsOptions = {
          compression = "lz4";      # Fast compression by default
          atime = "off";            # No access time updates (performance)
          xattr = "sa";             # Extended attributes in system attribute
          acltype = "posixacl";     # POSIX ACLs for Linux compatibility
        };

        datasets = {
          # ============================================
          # Root Dataset (Not Mounted)
          # ============================================
          "storage" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };

          # ============================================
          # Media Storage
          # ============================================
          "storage/media" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };

          # Family Photos/Videos - MAXIMUM PROTECTION
          # Irreplaceable data gets paranoid settings
          "storage/media/family-media" = {
            type = "zfs_fs";
            mountpoint = "/storage/media/family-media";
            options = {
              recordsize = "1M";           # Optimized for large photo/video files
              compression = "lz4";         # Fast compression with some benefit
              copies = "2";                # Store 2 copies within mirror (paranoid mode)
              checksum = "sha256";         # Strongest checksumming for irreplaceable data
              xattr = "sa";                # Extended attributes for PhotoPrism metadata
            };
          };

          # Security Cameras (Frigate) - HIGH THROUGHPUT
          # Continuous recording prioritizes write performance
          "storage/media/security-cameras" = {
            type = "zfs_fs";
            mountpoint = "/storage/media/security-cameras";
            options = {
              recordsize = "1M";           # Large video files
              compression = "off";         # Video already H.264 compressed
              primarycache = "metadata";   # Don't cache video data in ARC (save RAM)
              logbias = "throughput";      # Optimize for streaming writes
              sync = "disabled";           # Accept risk for performance (recordings expendable)
            };
          };

          # ============================================
          # Borg Backup Repository - SPACE EFFICIENCY
          # ============================================
          "storage/borgbackup" = {
            type = "zfs_fs";
            mountpoint = "/storage/borgbackup";
            options = {
              recordsize = "1M";           # Large backup archives
              compression = "zstd-3";      # Better compression than lz4 (CPU available)
              checksum = "sha256";         # Stronger than default fletcher4
            };
          };

          # ============================================
          # General Data (Fallback)
          # ============================================
          "storage/data" = {
            type = "zfs_fs";
            mountpoint = "/storage/data";
            options = {
              recordsize = "128K";         # Balanced for mixed workloads
              compression = "lz4";
            };
          };
        };
      };
    };
  };

  # ============================================
  # Bulk Storage Path Reference
  # ============================================
  # Used by services to locate data storage
  bulkStorage.path = "/storage";

  # Note: Old ext4 mount removed - ZFS now manages /storage
}
