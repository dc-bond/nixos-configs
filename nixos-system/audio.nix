{ 
  lib, 
  pkgs, 
  config, 
  ... 
}: 

{

  security.rtkit.enable = true; # RealtimeKit system service, which hands out realtime scheduling priority to user processes on demand
  
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
  };

}