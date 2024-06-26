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

  #xdg.configFile = let
  #  floatFont = lib.strings.floatToString 10;
  #  qtconf =
  #    ''
  #      [Fonts]
  #      fixed="Sans Serif,${floatFont},-1,5,50,0,0,0,0,0"
  #      general="Sans Serif,${floatFont},-1,5,50,0,0,0,0,0"

  #      [Appearance]
  #      icon_theme=Flat-Remix-Violet-Dark
  #      style=
  #    '';
  #in {
  #  "Kvantum/Dracula/Dracula.kvconfig".source = "${pkgs.dracula-theme}/share/Kvantum/Dracula-purple-solid/Dracula-purple-solid.kvconfig";
  #  "Kvantum/Dracula/Dracula.svg".source = "${pkgs.dracula-theme}/share/Kvantum/Dracula-purple-solid/Dracula-purple-solid.svg";
  #  "Kvantum/kvantum.kvconfig".text = "[General]\ntheme=Dracula";
  #  "qt5ct/qt5ct.conf".text = qtconf + "kvantum";
  #  "qt6ct/qt6ct.conf".text = qtconf + "kvantum";
  #};
}