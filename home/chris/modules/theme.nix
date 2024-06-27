{ config, lib, pkgs, ... }: 

{

  home.packages = with pkgs; [
    libsForQt5.qtstyleplugin-kvantum
    qt6Packages.qtstyleplugin-kvantum
  ];
    
  home.pointerCursor = {
    name = "WhiteSur-cursors";
    package = pkgs.whitesur-cursors;
    size = 20;
    gtk.enable = true;
    x11 = {
      enable = true;
      defaultCursor = "WhiteSur-cursors";
    };
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
      size = 10;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
  };

}