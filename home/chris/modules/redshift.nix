{ config, pkgs, ... }: 

{

# redshift
  services.redshift = {
    enable = true;
    latitude = 40.456660;
    longitude = -79.949580;
    temperature.day = 6500;
    temperature.night = 3900;
  };

}
