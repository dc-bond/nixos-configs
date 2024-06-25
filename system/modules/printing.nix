{ lib, config, pkgs, ... }: 

{

  services.printing.cups-pdf = {
    enable = true;
  };

}