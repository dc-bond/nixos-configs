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