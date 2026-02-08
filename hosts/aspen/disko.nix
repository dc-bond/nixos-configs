{
  inputs,
  config,
  configVars,
  pkgs,
  ...
}: 

{

  imports = [ inputs.disko.nixosModules.disko ];

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
                  # CURRENT LAYOUT (traditional root - to be replaced on fresh install)
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
    };
  };

  bulkStorage.path = "/storage"; # Western Digital 4TB SATA HDD ata-WDC_WD40EFRX-68N32N0_WD-WCC7K4RU947F

  fileSystems."/storage" = {
    device = "/dev/disk/by-uuid/2dbedc67-9a6b-477f-a3b4-75116994d1cb";
    fsType = "ext4";
    options = [ "defaults" ];
  };

}