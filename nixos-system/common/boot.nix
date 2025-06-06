{ 
  pkgs, 
  ... 
}: 

{

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 3; # only display last 3 generations
      };
      efi.canTouchEfiVariables = true;
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