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
    font = "SauceCodePro Nerd Font 10";
    location = "center";
    extraConfig = {
      #modes = "window,drun,run,ssh,combi,calc,power-menu:${pkgs.rofi-power-menu}/bin/rofi-power-menu";
      display-combi = "Combination Mode";
      display-run = "Shell Scripts";
      display-drun = "Applications";
      display-ssh = "SSH";
      display-calc = "Calculator";
    };
  };

}