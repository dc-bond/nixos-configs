{ pkgs, ... }: 

{

# rofi
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    plugins = with pkgs; [
      rofi-calc
      rofi-power-menu
    ];
    terminal = "${pkgs.alacritty}/bin/alacritty";
    font = "SauceCodePro Nerd Font 10";
    location = "center";
    theme = ../dotfiles/rofi/Ayu-Mirage.rasi;
    extraConfig = {
      #modes = "window,drun,run,ssh,combi,calc,power-menu:${pkgs.rofi-power-menu}/bin/rofi-power-menu";
      display-combi = "Combination Mode";
      display-run = "Shell Scripts";
      display-drun = "Applications";
      display-ssh = "SSH";
      display-calc = "Calculator";
      border = 0;
      border-radius = 0;
      padding = 16 14;
      width = 500px;
    };
  };

}