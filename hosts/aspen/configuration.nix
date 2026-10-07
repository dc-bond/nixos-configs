{
  inputs,
  outputs,
  lib,
  configLib,
  config,
  configVars,
  pkgs,
  ...
}:

{

  networking = {
    hostName = "aspen";
    hostId = "a2d3cb8e"; # must remain constant across reinstalls for zfs pool auto-import
  };

  # disko disk formatting occurs once on first deployment
  # data drives (disk1, disk2) are commented out to prevent accidental reformatting during OS reinstalls
  # commented-out configs below document how drives were originally provisioned by disko
  # after initial provisioning, drives are managed via fileSystems + services.zfsExtended
  disko.devices = {
    disk = {

      disk0 = {
        type = "disk";
        device = configVars.hosts.${config.networking.hostName}.hardware.disk0;
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
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/persist" = {
                    mountpoint = "/persist";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
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

      # disk1 = {
      #   type = "disk";
      #   device = configVars.hosts.${config.networking.hostName}.hardware.disk1;
      #   content = {
      #     type = "gpt";
      #     partitions = {
      #       zfs = {
      #         size = "100%";
      #         content = {
      #           type = "zfs";
      #           pool = "storage";
      #         };
      #       };
      #     };
      #   };
      # };

      # disk2 = {
      #   type = "disk";
      #   device = configVars.hosts.${config.networking.hostName}.hardware.disk2;
      #   content = {
      #     type = "gpt";
      #     partitions = {
      #       zfs = {
      #         size = "100%";
      #         content = {
      #           type = "zfs";
      #           pool = "storage";
      #         };
      #       };
      #     };
      #   };
      # };

    };

    # zpool = {
    #   storage = {
    #     type = "zpool";
    #     mode = "mirror";
    #     options = {
    #       ashift = "12"; # 4K sector size
    #     };
    #     rootFsOptions = {
    #       compression = "lz4";      # fast compression by default
    #       atime = "off";            # disable access time tracking
    #       xattr = "sa";             # extended attributes inline
    #       acltype = "posixacl";     # POSIX ACLs
    #       mountpoint = "none";      # prevent pool root from auto-mounting
    #     };
    #     mountpoint = null; # don't create NixOS fileSystems entry for pool root
    #     datasets = {
    #
    #       "root" = { # organizational parent dataset for entire pool
    #         type = "zfs_fs";
    #         mountpoint = "/storage-zfs";
    #         options = {
    #           mountpoint = "legacy";       # systemd manages mounting via fileSystems
    #         };
    #       };
    #
    #       "root/media" = { # organizational parent dataset for media directory, not mounted
    #         type = "zfs_fs";
    #         options = {
    #           mountpoint = "none";
    #         };
    #       };
    #
    #       "root/media/family-media" = {
    #         type = "zfs_fs";
    #         mountpoint = "/storage-zfs/media/family-media";
    #         options = {
    #           mountpoint = "legacy";       # systemd manages mounting via fileSystems
    #           recordsize = "1M";           # optimized for large files
    #           compression = "lz4";         # fast compression
    #           xattr = "sa";                # PhotoPrism metadata support
    #         };
    #       };
    #
    #       "root/media/security-cameras" = {
    #         type = "zfs_fs";
    #         mountpoint = "/storage-zfs/media/security-cameras";
    #         options = {
    #           mountpoint = "legacy";       # systemd manages mounting via fileSystems
    #           recordsize = "1M";           # large video files
    #           compression = "off";         # video already H.264 compressed
    #           primarycache = "metadata";   # don't cache video in ARC
    #           logbias = "throughput";      # optimize for streaming
    #           sync = "disabled";           # accept risk of data corruption on power loss for performance
    #         };
    #       };
    #
    #       "root/media/library" = {
    #         type = "zfs_fs";
    #         mountpoint = "/storage-zfs/media/library";
    #         options = {
    #           mountpoint = "legacy";       # systemd manages mounting via fileSystems
    #           recordsize = "1M";           # large sequential files
    #           compression = "lz4";         # fast compression
    #         };
    #       };
    #
    #       "root/borgbackup" = {
    #         type = "zfs_fs";
    #         mountpoint = "/storage-zfs/borgbackup";
    #         options = {
    #           mountpoint = "legacy";       # systemd manages mounting via fileSystems
    #           recordsize = "1M";           # large backup archives
    #           compression = "off";         # borg handles compression (zstd,8)
    #         };
    #       };
    #
    #       "root/games" = {
    #         type = "zfs_fs";
    #         mountpoint = "/home/chris/games";
    #         options = {
    #           mountpoint = "legacy";       # systemd manages mounting via fileSystems
    #           recordsize = "128K";         # suited to game binaries and ROM files (smaller than media 1M)
    #           compression = "lz4";         # ROMs and binaries compress well
    #         };
    #       };
    #
    #       "root/cache" = { # organizational parent dataset for regenerable application caches, not mounted
    #         type = "zfs_fs";
    #         options = {
    #           mountpoint = "none";
    #         };
    #       };
    #
    #       "root/cache/photoprism" = {
    #         type = "zfs_fs";
    #         mountpoint = "/storage-zfs/cache/photoprism";
    #         options = {
    #           mountpoint = "legacy";       # systemd manages mounting via fileSystems
    #           compression = "off";         # thumbnails are already JPEG compressed
    #         };
    #       };
    #
    #       "root/reserved" = { # theoretically prevent fragmentation by proactively setting aside a chunk of space, then delete if approaching capacity to free up that space
    #         type = "zfs_fs";
    #         options = {
    #           mountpoint = "none";         # not mounted (placeholder only)
    #           reservation = "2400G";       # 20% of 12TB usable capacity
    #           quota = "2400G";             # prevent growth beyond reservation
    #         };
    #       };
    #
    #     };
    #   };
    # };

  };

  bulkStorage.path = "/storage-zfs";

  fileSystems = {

    # zfs pool root dataset comprised of two 12TB SATA HDDs
    "/storage-zfs" = {
      device = "storage/root";
      fsType = "zfs";
      options = [ "nofail" ];
    };

    # zfs child datasets explicitly defined here since we use legacy systemd-managed mountpoints
    "/storage-zfs/media/family-media" = {
      device = "storage/root/media/family-media";
      fsType = "zfs";
      options = [ "nofail" ];
    };
    "/storage-zfs/media/security-cameras" = {
      device = "storage/root/media/security-cameras";
      fsType = "zfs";
      options = [ "nofail" ];
    };
    "/storage-zfs/media/library" = {
      device = "storage/root/media/library";
      fsType = "zfs";
      options = [ "nofail" ];
    };
    "/storage-zfs/borgbackup" = {
      device = "storage/root/borgbackup";
      fsType = "zfs";
      options = [ "nofail" ];
    };
    "/storage-zfs/cache/photoprism" = {
      device = "storage/root/cache/photoprism";
      fsType = "zfs";
      options = [ "nofail" ];
    };

    # games: mounted directly from ZFS — no impermanence binding needed
    # dataset created imperatively: see commented-out disko config above for provenance
    "/home/chris/games" = {
      device = "storage/root/games";
      fsType = "zfs";
      options = [ "nofail" ];
    };
  };

  services.zfsExtended = {
    enable = true;
    pools = [ "storage" ]; # auto-import storage pool at boot
    enableSnapshots = false;
    datasetQuotas = {
      # unbounded frigate footage shares the pool with nextcloud, photoprism and
      # the borg repo; ~1.3T projected across five cameras. dataset name rather
      # than a bulkStorage path because these datasets are mountpoint=legacy
      "storage/root/media/security-cameras" = "2T";
      "storage/root/cache/photoprism" = "1T"; # photoprism never evicts on-demand thumbnails
    };
  };

  systemd.services.zfs-mount.enable = false; # disable zfs auto-mount service when using legacy systemd-managed mountpoints

  # silent hard hangs leave no log and need a power cycle; the sp5100_tco
  # hardware watchdog reboots the host when pid 1 stops petting it
  systemd.settings.Manager.RuntimeWatchdogSec = "30s";
  boot.kernel.sysctl = {
    "kernel.panic" = 10; # reboot 10s after a panic instead of sitting on it
    "kernel.softlockup_panic" = 1;
  };

  backups = {
    startTime = "*-*-* 02:20:00";
    borgDir = "${config.bulkStorage.path}/borgbackup";
    standaloneData = [
      "${config.bulkStorage.path}/media/family-media"
    ];
  };

  # original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "25.11";

  imports = lib.flatten [
    inputs.disko.nixosModules.disko
    inputs.private.nixosModules.oci-communitycluster2026
    inputs.private.nixosModules.oci-wardrobe
    (map configLib.relativeToRoot [
      "hosts/aspen/hardware-configuration.nix"
      "hosts/aspen/impermanence.nix"
      "nixos-system/boot.nix"
      "nixos-system/foundation.nix"
      "nixos-system/base-tools.nix"
      "nixos-system/networking.nix"
      #"nixos-system/crowdsec.nix"
      "nixos-system/users.nix"
      "nixos-system/sshd.nix"
      "nixos-system/zsh.nix"
      "nixos-system/sops.nix"
      "nixos-system/btrfs.nix"
      "nixos-system/zfs.nix"
      "nixos-system/tailscale.nix" # recoverTailscale
      "nixos-system/monitoring-client.nix"
      "nixos-system/backups.nix"
      "nixos-system/postgresql.nix"
      "nixos-system/mysql.nix"
      "nixos-system/traefik.nix"
      "nixos-system/nvidia.nix"
      "nixos-system/sunshine.nix"
      "nixos-system/oci-containers.nix"
      "nixos-system/oci-pihole.nix"
      "nixos-system/lldap.nix" # recoverLldap
      "nixos-system/authelia-dcbond.nix" # recoverAuthelia-dcbond
      "nixos-system/nextcloud.nix" # recoverNextcloud
      "nixos-system/photoprism.nix" # recoverPhotoprism
      "nixos-system/home-assistant.nix" # recoverHome-assistant
      "nixos-system/oci-frigate.nix"
      "nixos-system/oci-zwavejs.nix" # recoverZwavejs
      "nixos-system/zigbee2mqtt.nix" # recoverZigbee2mqtt
      "nixos-system/unifi.nix" # recoverUnifi
      "nixos-system/oci-media-server.nix" # recoverMedia-server
      "nixos-system/oci-metube.nix" # recoverMetube
      "nixos-system/oci-actual.nix" # recoverActual
      "nixos-system/fava.nix"
      "nixos-system/oci-recipesage.nix" # recoverRecipesage
      "nixos-system/oci-n8n.nix" # recoverN8n
      "nixos-system/vikunja.nix"
      "nixos-system/ollama.nix"
      "nixos-system/stirling-pdf.nix"
      "nixos-system/dcbond-root.nix"
      "scripts/media-transfer.nix"
      #"scripts/network-test.nix"
    ])
  ];

}
