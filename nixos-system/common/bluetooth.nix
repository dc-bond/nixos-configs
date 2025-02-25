{ pkgs, 
  ... 
}: 

{

  services.blueman.enable = true; # terminal-based bluetooth connection tool
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

}