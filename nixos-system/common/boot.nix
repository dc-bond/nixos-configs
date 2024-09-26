{ 
  pkgs, 
  ... 
}: 

{

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10; # only display last 10 generations
      };
      efi.canTouchEfiVariables = true;
    };
    kernel.sysctl = { "vm.swappiness" = 30;};
    initrd.preLVMCommands = # turn on keyboard num-lock automatically during boot process
    ''
      ${pkgs.kbd}/bin/setleds +num
    '';
  };

}