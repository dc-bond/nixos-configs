{ 
  config, 
  lib, 
  pkgs, 
  ... 
}: 

{

  gtk = {
    enable = true;
    theme = {
      name = "Materia-light";
      package = pkgs.materia-theme;
    };
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-nord;
    };
    font = {
      name = "Source Sans Pro";
      package = null; # already installed in fonts.nix system-level module
      size = 10;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = false;  # since using materia light
    };
  };

  #qt = {
  #  enable = true;
  #  platformTheme.name = "qtct";
  #};

}