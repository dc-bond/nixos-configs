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
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_103227147"; # virtual disk id
        #device = "/dev/sda";  # virtual disk path
        content = {
          type = "gpt";
          partitions = {
  
            bios-grub = {
              size = "2M";
              type = "EF02";
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
                    swap.swapfile.size = "8G";
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