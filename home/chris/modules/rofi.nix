{ config, pkgs, ... }: 

{

# rofi
  home.file."${config.xdg.configHome}/rofi" = {
    source = ../dotfiles/rofi;
    recursive = true;
  };

  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    plugins = with pkgs; [
      rofi-calc
    ];
    terminal = "${pkgs.alacritty}/bin/alacritty";
    theme = ../dotfiles/rofi/Ayu-Mirage.rasi;
  };

}