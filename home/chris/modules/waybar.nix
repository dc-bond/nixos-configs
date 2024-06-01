{ config, pkgs, ... }: 

{

  home.file."${config.xdg.configHome}/waybar" = {
    source = ../dotfiles/waybar;
    recursive = true;
  };

  home.packages = with pkgs; [
    waybar
    (pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    })
    )
  ]

  #programs.waybar = {
  #  enable = true;
  #  #settings = { 
  #  #  lib.importJSON = ../dotfiles/waybar/config.json;
  #  #};
  #  #style = ''
  #  #'';
  #};

}