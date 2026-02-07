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
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/persist" = {
                    mountpoint = "/persist";
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

  ## Western Digital 4TB USB HDD Serial WD-WX21DC86RU3P
  #bulkStorage.path = "/storage";

  #fileSystems."/storage" = {
  #  device = "/dev/disk/by-uuid/f3fb53cc-52fa-48e3-8cac-b69d85a8aff1";
  #  fsType = "ext4";
  #  options = [
  #    "defaults"  # standard mount options
  #    "nofail"    # don't fail boot if drive is unplugged
  #    "noatime"   # don't update access times (better performance, less wear)
  #  ];
  #};

}