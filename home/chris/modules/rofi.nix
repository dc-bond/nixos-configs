{ config, pkgs, ... }: 

{

  home.file."${config.xdg.configHome}/rofi" = {
    source = ../dotfiles/rofi;
    recursive = true;
  };

  home.packages = with pkgs; [
    pinentry-rofi # use rofi for pinentry
    rofi-calc # calculator add-on for rofi
    #rofi-pass-wayland # add pass functionality to rofi
  ];

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
