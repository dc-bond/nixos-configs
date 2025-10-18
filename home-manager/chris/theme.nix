{ 
  config, 
  lib, 
  pkgs, 
  ... 
}: 

{

  #home.packages = with pkgs; [
  #  libsForQt5.qtstyleplugin-kvantum
  #  qt6Packages.qtstyleplugin-kvantum
  #];
    
  home.pointerCursor = {
    enable = true;
    name = "WhiteSur-cursors";
    package = pkgs.whitesur-cursors;
    size = 20;
    gtk.enable = true; # integrate with gtk apps
    hyprcursor = { # integrate with hyprland
      enable = true;
      size = 20;
    };
    #x11 = {
    #  enable = true;
    #  defaultCursor = "WhiteSur-cursors";
    #};
  };

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