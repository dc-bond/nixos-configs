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
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              label = "boot";
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
              label = "luks";
              content = {
                type = "luks";
                name = "cryptroot";
                settings = {
                  allowDiscards = true;
                };
                passwordFile = "/tmp/crypt-passwd.txt"; # interactive login
                content = {
                  type = "btrfs";
                  extraArgs = [ "-L" "nixos" "-f" ];
                  postCreateHook = ''
                    mntpoint=$(mktemp -d)
                    mount "/dev/mapper/cryptroot" "$mntpoint" -o subvol=/
                    trap 'umount $mntpoint; rm -rf $mntpoint' EXIT
                    btrfs subvolume snapshot -r $mntpoint/root $mntpoint/root-blank
                  '';
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [ "subvol=root" "compress=zstd" "noatime" ];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [ "subvol=home" "compress=zstd" "noatime" ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "subvol=nix" "compress=zstd" "noatime" ];
                    };
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = [ "subvol=persist" "compress=zstd" "noatime" ];
                    };
                    "/log" = {
                      mountpoint = "/var/log";
                      mountOptions = [ "subvol=log" "compress=zstd" "noatime" ];
                    };
                    "/swap" = {
                      mountpoint = "/swap";
                      swap.swapfile.size = "16G"; # double system memory
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

  fileSystems = {
    "/persist".neededForBoot = true;
    "/var/log".neededForBoot = true;
  };
  
}