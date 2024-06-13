{ config, pkgs, ... }: 

{

# gammastep
  services.gammastep = {
    enable = true;
    latitude = 40.46;
    longitude = -79.95;
    temperature.day = 6500;
    temperature.night = 3900;
    dawnTime = "4:00-7:45";
    duskTime = "18:30-20:00";
  };

}
