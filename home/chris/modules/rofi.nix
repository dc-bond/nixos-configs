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
      modes = "window,drun,run,ssh,combi,calc,power-menu:${pkgs.rofi-power-menu}/bin/rofi-power-menu";
    };
  };

}