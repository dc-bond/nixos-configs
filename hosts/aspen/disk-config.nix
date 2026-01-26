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
    };
  };

  # ============================================
  # Data Pool (ext4 HDD, will become ZFS mirror)
  # ============================================
  dataPool.path = "/data-pool-hdd";

  fileSystems."/data-pool-hdd" = {
    device = "/dev/disk/by-uuid/2dbedc67-9a6b-477f-a3b4-75116994d1cb";
    fsType = "ext4";
    options = [ "defaults" ];
  };

  # After ZFS migration, change above to:
  # fileSystems."/data-pool-hdd" = {
  #   device = "data-pool-hdd";
  #   fsType = "zfs";
  # };

}