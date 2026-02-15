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
  disko.devices = {
    disk = {

      main = {
      #disk0 = {
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
                    swap.swapfile.size = "8G"; # 0.25x RAM - adequate OOM protection for well-provisioned server
                  };

                  # FRESH INSTALL LAYOUT (impermanence - uncomment and remove above on fresh install)
                  #"/nix" = {
                  #  mountpoint = "/nix";
                  #  mountOptions = [ "compress=zstd" "noatime" ];
                  #};
                  #"/persist" = {
                  #  mountpoint = "/persist";
                  #  mountOptions = [ "compress=zstd" "noatime" ];
                  #};
                  #"/snapshots" = {
                  #  mountpoint = "/snapshots";
                  #  mountOptions = [ "compress=zstd" "noatime" ];
                  #};
                  #"/swap" = {
                  #  mountpoint = "/swap";
                  #  swap.swapfile.size = "8G"; # 0.25x RAM - adequate OOM protection for well-provisioned server
                  #};
                };
              };
            };
          };
        };
      };

      #disk1 = {
      #  type = "disk";
      #  device = configVars.hosts.${config.networking.hostName}.hardware.disk1;
      #  content = {
      #    type = "gpt";
      #    partitions = {
      #      zfs = {
      #        size = "100%";
      #        content = {
      #          type = "zfs";
      #          pool = "storage";
      #        };
      #      };
      #    };
      #  };
      #};

      #disk2 = {
      #  type = "disk";
      #  device = configVars.hosts.${config.networking.hostName}.hardware.disk2;
      #  content = {
      #    type = "gpt";
      #    partitions = {
      #      zfs = {
      #        size = "100%";
      #        content = {
      #          type = "zfs";
      #          pool = "storage";
      #        };
      #      };
      #    };
      #  };
      #};

    };

    #zpool = {
    #  storage = {
    #    type = "zpool";
    #    mode = "mirror";
    #    options = {
    #      ashift = "12"; # 4K sector size
    #    };
    #    rootFsOptions = {
    #      compression = "lz4";      # fast compression by default
    #      atime = "off";            # disable access time tracking
    #      xattr = "sa";             # extended attributes inline
    #      acltype = "posixacl";     # POSIX ACLs
    #    };
    #    mountpoint = null; # pool root not mounted directly
    #    datasets = {

    #      "root" = { # organizational parent dataset for entire pool
    #        type = "zfs_fs";
    #        mountpoint = "/storage-zfs";
    #      };
    #
    #      "root/media" = { # organizational parent dataset for media directory, not mounted
    #        type = "zfs_fs";
    #        options = {
    #          mountpoint = "none";
    #        };
    #      };
    #
    #      "root/media/family-media" = {
    #        type = "zfs_fs";
    #        mountpoint = "/storage-zfs/media/family-media";
    #        options = {
    #          recordsize = "1M";           # optimized for large files
    #          compression = "lz4";         # fast compression
    #          xattr = "sa";                # PhotoPrism metadata support
    #        };
    #      };
    #
    #      "root/media/security-cameras" = {
    #        type = "zfs_fs";
    #        mountpoint = "/storage-zfs/media/security-cameras";
    #        options = {
    #          recordsize = "1M";           # large video files
    #          compression = "off";         # video already H.264 compressed
    #          primarycache = "metadata";   # don't cache video in ARC
    #          logbias = "throughput";      # optimize for streaming
    #          sync = "disabled";           # accept risk of data corruption on power loss for performance
    #        };
    #      };
    #
    #      "root/media/library" = {
    #        type = "zfs_fs";
    #        mountpoint = "/storage-zfs/media/library";
    #        options = {
    #          recordsize = "1M";           # large sequential files
    #          compression = "lz4";         # fast compression
    #        };
    #      };
    #
    #      "root/borgbackup" = {
    #        type = "zfs_fs";
    #        mountpoint = "/storage-zfs/borgbackup";
    #        options = {
    #          recordsize = "1M";           # large backup archives
    #          compression = "off";         # borg handles compression (zstd,8)
    #        };
    #      };
    #
    #      "root/reserved" = { # theoretically prevent fragmentation by proactively setting aside a chunk of space, then delete if approaching capacity to free up that space
    #        type = "zfs_fs";
    #        options = {
    #          mountpoint = "none";         # not mounted (placeholder only)
    #          reservation = "2400G";       # 20% of 12TB usable capacity
    #          quota = "2400G";             # prevent growth beyond reservation
    #        };
    #      };

    #    };
    #  };
    #};

  };

  bulkStorage.path = "/storage-ext4"; # update to /storage-zfs after zfs pool online

  fileSystems = {
    "/storage-ext4" = {
      device = "/dev/disk/by-uuid/2dbedc67-9a6b-477f-a3b4-75116994d1cb"; # western digital 4TB SATA HDD (ata-WDC_WD40EFRX-68N32N0_WD-WCC7K4RU947F)
      fsType = "ext4";
      options = [ "defaults" ];
    };
    #"/storage-zfs" = { # uncomment after zfs pool online
    #  device = "storage/root";
    #  fsType = "zfs";
    #};
  };

  services.zfsExtended = {
    enable = true;
    pools = [ "storage" ]; # auto-import storage pool at boot
    enableSnapshots = true;
  };

  backups = {
    borgDir = "${config.bulkStorage.path}/borgbackup";
    standaloneData = [
      "${config.bulkStorage.path}/media/family-media"
    ];
  };

  #btrfs.snapshots = true; # enable hourly + recovery snapshots and recoverSnap script

  environment.systemPackages = with pkgs; [
    wget # download tool
    usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
    smartmontools # provides smartctl command for disk health monitoring
    rsync # sync tool
    btop # system monitor
    tmux # terminal multiplexer for persistent sessions
    bind # dns lookup tool
  ];

  # original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "24.11";

  imports = lib.flatten [
    inputs.disko.nixosModules.disko
    (map configLib.relativeToRoot [
      # RECOVERY 0: Foundation - no recovery needed, verify SSH/ZFS/secrets after reboot
      "hosts/aspen/hardware-configuration.nix" # 0
      "nixos-system/boot.nix" # 0
      "nixos-system/foundation.nix" # 0
      #"hosts/aspen/impermanence.nix" # 0
      "nixos-system/networking.nix" # 0
      "nixos-system/users.nix" # 0
      "nixos-system/sshd.nix" # 0
      "nixos-system/zsh.nix" # 0
      "nixos-system/sops.nix" # 0
      "nixos-system/btrfs.nix" # 0
      "nixos-system/zfs.nix" # 0 (verify pool auto-imports)
      "nixos-system/tailscale.nix" # 0

      # RECOVERY 1: Core Infrastructure - deploy together, no recovery yet (databases start empty)
      "nixos-system/postgresql.nix" # 1
      "nixos-system/mysql.nix" # 1
      "nixos-system/traefik.nix" # 1
      "nixos-system/monitoring-client.nix" # 1
      "nixos-system/nvidia.nix" # 1
      "nixos-system/backups.nix" # 1 (recovery scripts infrastructure)
      "nixos-system/samba.nix" # 1
      "nixos-system/oci-containers.nix" # 1 (docker base - required by all OCI services)
      "nixos-system/oci-pihole.nix" # 1 (DNS - 100% declarative rebuild via pihole-init)

      # RECOVERY 2: LLDAP - deploy alone, run: sudo recoverLldap
      "nixos-system/lldap.nix" # 2 (requires postgresql.nix)

      # RECOVERY 3: Authelia - deploy after LLDAP working, run: sudo recoverAuthelia-dcbond
      "nixos-system/authelia-dcbond.nix" # 3 (requires lldap.nix)

      # RECOVERY 4: Nextcloud - deploy alone (complex), run: sudo recoverNextcloud
      "nixos-system/nextcloud.nix" # 4 (requires postgresql.nix)

      # RECOVERY 5: Core Apps - deploy together, run recoveries: sudo recoverPhotoprism && sudo recoverHomeAssistant
      "nixos-system/photoprism.nix" # 5 (requires mysql.nix)
      "nixos-system/home-assistant.nix" # 5 (requires postgresql.nix)

      # RECOVERY 6: Home Automation - deploy together, run recoveries (frigate optional - see audit notes)
      "nixos-system/oci-frigate.nix" # 6 (requires nvidia.nix; optional recovery)
      "nixos-system/oci-zwavejs.nix" # 6 (run: sudo recoverZwavejs)
      "nixos-system/oci-unifi.nix" # 6 (run: sudo recoverUnifi)

      # RECOVERY 7: Productivity - deploy together, run recoveries (fava/calibre optional - see audit notes)
      "nixos-system/oci-actual.nix" # 7 (run: sudo recoverActual)
      "nixos-system/oci-fava.nix" # 7 (no recovery - reads from Nextcloud)
      "nixos-system/oci-recipesage.nix" # 7 (run: sudo recoverRecipesage)
      "nixos-system/oci-n8n.nix" # 7 (run: sudo recoverN8n)
      "nixos-system/calibre.nix" # 7 (optional recovery - reading progress only)

      # RECOVERY 8: Utilities - deploy together, no recoveries (all stateless or ephemeral)
      "nixos-system/stirling-pdf.nix" # 8 (stateless)
      "nixos-system/ollama.nix" # 8 (can re-download models)
      "nixos-system/oci-searxng.nix" # 8 (stateless - tmpfs cache)
      "nixos-system/nginx-sites.nix" # 8 (reads from Nextcloud)
      "nixos-system/dcbond-root.nix" # 8 (reads from Nextcloud)
      "nixos-system/crowdsec.nix" # 8 (ephemeral state)

      # RECOVERY 9: Media Stack - deploy together, run: sudo recoverMedia-server
      "nixos-system/oci-media-server.nix" # 9 (restores 6 containers at once)
      "scripts/media-transfer.nix" # 9 (no recovery - just scripts)
      "scripts/dns-test.nix" # 9
    ])
  ];

}