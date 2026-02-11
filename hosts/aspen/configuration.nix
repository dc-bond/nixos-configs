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
        device = configVars.hosts.${config.networking.hostName}.hardware.btrfsOsDisk;
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
      #  device = "/dev/disk/by-id/ata-DRIVE1_SERIAL"; # REPLACE: Get from 'ls -l /dev/disk/by-id/' after burn-in
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
      #  device = "/dev/disk/by-id/ata-DRIVE2_SERIAL"; # REPLACE: Get from 'ls -l /dev/disk/by-id/' after burn-in
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

  environment.systemPackages = with pkgs; [
    wget # download tool
    usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
    smartmontools # provides smartctl command for disk health monitoring
    rsync # sync tool
    btop # system monitor
  ];

  # original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "24.11";

  imports = lib.flatten [
    inputs.disko.nixosModules.disko
    (map configLib.relativeToRoot [
      "hosts/aspen/hardware-configuration.nix"
      #"hosts/aspen/impermanence.nix"
      "nixos-system/boot.nix"
      "nixos-system/foundation.nix"
      "nixos-system/networking.nix"
      "nixos-system/crowdsec.nix"
      "nixos-system/tailscale.nix"
      "nixos-system/users.nix"
      "nixos-system/sshd.nix"
      "nixos-system/zsh.nix"
      "nixos-system/backups.nix"
      "nixos-system/btrfs.nix"
      "nixos-system/zfs.nix"
      "nixos-system/sops.nix"
      "nixos-system/nvidia.nix"
      "nixos-system/samba.nix"

      "nixos-system/postgresql.nix"
      "nixos-system/monitoring-client.nix"
      "nixos-system/traefik.nix"
      "nixos-system/mysql.nix"
      "nixos-system/photoprism.nix" # requires mysql.nix
      "nixos-system/lldap.nix" # requires postgresql.nix
      "nixos-system/calibre.nix"
      "nixos-system/nginx-sites.nix"
      "nixos-system/nextcloud.nix" # requires postgresql.nix
      "nixos-system/home-assistant.nix" # requires postgresql.nix
      "nixos-system/authelia-dcbond.nix" # requires lldap.nix
      "nixos-system/stirling-pdf.nix"
      "nixos-system/dcbond-root.nix"
      "nixos-system/ollama.nix"
      "nixos-system/oci-containers.nix"
      "nixos-system/oci-fava.nix"
      "nixos-system/oci-frigate.nix" # requires nvidia.nix
      "nixos-system/oci-pihole.nix"
      "nixos-system/oci-actual.nix"
      "nixos-system/oci-zwavejs.nix"
      "nixos-system/oci-searxng.nix"
      "nixos-system/oci-recipesage.nix"
      "nixos-system/oci-unifi.nix"
      "nixos-system/oci-n8n.nix"
      "nixos-system/oci-media-server.nix"

      "scripts/media-transfer.nix"
    ])
  ];

}