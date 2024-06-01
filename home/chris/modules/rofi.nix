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
    #font = "SauceCodePro Nerd Font 10";
    #location = "center";
    theme = ../dotfiles/rofi/Ayu-Mirage.rasi;
    #xoffset = ;
    #yoffset = 29;
    extraConfig = {
      modes = "window,drun,run,ssh,combi,calc,power-menu:${pkgs.rofi-power-menu}/bin/rofi-power-menu";
      display-combi = "Combination Mode";
      display-run = "Shell Scripts";
      display-drun = "Applications";
      display-ssh = "SSH";
      display-calc = "Calculator";
    };
    window = {
      "font" = mkLiteral "SauceCodePro Nerd Font 10";
      "location" = mkLiteral "center";
      "border" = mkLiteral "0";
      "border-radius" = mkLiteral "0";
      "padding" = mkLiteral "16 14";
      "width" = mkLiteral "500px";
      "y-offset" = mkLiteral "29";
    }';
  };

}