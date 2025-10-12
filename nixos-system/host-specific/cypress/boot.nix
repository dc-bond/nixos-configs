{ 
  pkgs, 
  ... 
}: 

{

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5; # only display last 5 generations
      };
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = {
      btrfs = true;
    };
    kernel.sysctl = { "vm.swappiness" = 30;};
    initrd = {
      supportedFilesystems = {
        btrfs = true;
      };
      preLVMCommands = ''
        ${pkgs.kbd}/bin/setleds +num
      '';
    };
  };

}