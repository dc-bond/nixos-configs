{ config, pkgs, ... }: 

{

  home.packages = with pkgs; [
    pinentry-rofi # use rofi for pinentry
  ];

  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    terminal = "${pkgs.alacritty}/bin/alacritty";
    font = "SauceCodePro Nerd Font 10";
    #pass = { # kinda garbage
    #  enable = true;
    #  package = pkgs.rofi-pass-wayland;
    #  stores = [ "${config.home.homeDirectory}/.password-store" ];
    #};
    theme = 
    let
      inherit (config.lib.formats.rasi) mkLiteral;
    in {
      "*" = {
        accentcolor = mkLiteral "#95e6cb";
        backgroundcolor = mkLiteral "#1f2430f3";
        foregroundcolor = mkLiteral "#bfbab0";
        selectioncolor = mkLiteral "#fafafa";
        separatorcolor = mkLiteral "transparent";
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@foregroundcolor";
      };
      "#window" = {
        location = mkLiteral "center";
        background-color = mkLiteral "@backgroundcolor";
        border-color = mkLiteral "@accentcolor";
        border = 0;
        border-radius = 0;
        padding = mkLiteral "16 14";
        width = mkLiteral "600px";
        y-offset = 29;
      };
      "#element" = {
        spacing = 2;
        padding = 8;
      };
      "#element.selected.normal" = {
        text-color = mkLiteral "@selectioncolor";
      };
      "#element.selected.active" = {
        text-color = mkLiteral "@selectioncolor";
      };
      "#inputbar" = {
        border = mkLiteral "none";
        children = map mkLiteral [ "prompt" "entry" ];
      };
      "#prompt" = {
        color = mkLiteral "@backgroundcolor";
        background-color = mkLiteral "@accentcolor";
        padding = mkLiteral "7 10 7 10";
      };
      "#entry" = {
        padding = mkLiteral "7 10 7 10";
      };
    };
    extraConfig = {
      #display-combi = "Combination Mode";
      display-run = "Launch";
      #display-drun = "Applications";
      display-ssh = "SSH";
    };
  };

}