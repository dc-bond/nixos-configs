{ 
  pkgs, 
  ... 
}: 

{

  hardware.bluetooth = {
    enable = true; # also installs bluez-utils to provide bluetoothctl terminal application
    powerOnBoot = true;
    settings = {
      Policy = {
        AutoEnable = true;
      };
    };
  };

  #services.blueman.enable = true; # gui application

}