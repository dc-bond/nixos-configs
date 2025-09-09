{ 
  pkgs, 
  ... 
}: 

{

  boot = {
    loader = {
      grub = {
        enable = true;
        efiSupport = false;
        configurationLimit = 3; # only display last 3 generations
      };
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = false;
    };
    supportedFilesystems = {
      btrfs = true;
      ext4 = true;
    };
    kernel.sysctl = { "vm.swappiness" = 30;};
    initrd = {
      supportedFilesystems = {
        btrfs = true;
        ext4 = true;
      };
      preLVMCommands = # turn on keyboard num-lock automatically during boot process
        ''
          ${pkgs.kbd}/bin/setleds +num
        '';
    };
  };

}