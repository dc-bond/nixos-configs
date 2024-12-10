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
      timeout = 10;
    };
    #kernelParams = [ "console=ttyS0,19200n8" ];
    kernel.sysctl = { "vm.swappiness" = 30;};
    supportedFilesystems.btrfs = true;
    initrd.supportedFilesystems.btrfs = true;
    # turn on keyboard num-lock automatically during boot process
    preLVMCommands = ''
      ${pkgs.kbd}/bin/setleds +num
    '';
  };

}