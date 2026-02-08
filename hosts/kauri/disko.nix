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
                      swap.swapfile.size = "8G"; # 0.5x RAM - adequate OOM protection without hibernation
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
                    #  swap.swapfile.size = "8G"; # 0.5x RAM - adequate OOM protection without hibernation
                    #};
                  };
                };
              };
            };
          };
        };
      };
    };
  };

}