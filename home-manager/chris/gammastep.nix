{ 
  config, 
  pkgs, 
  ... 
}: 

{

  services.gammastep = {
    enable = true;
    latitude = 40.46;
    longitude = -79.95;
    temperature.day = 6500;
    temperature.night = 4200;
    dawnTime = "07:45";
    duskTime = "19:00";
    settings = {
      general = {
        adjustment-method = "wayland";
        gamma = 0.8;
        location-provider = "manual";
        brightness-day = 1.0;
        brightness-night = 0.9;
        fade = 1;
      };
    };
  };

}
