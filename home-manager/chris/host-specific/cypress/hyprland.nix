{ 
  config,
  lib,
  configLib,
  pkgs, 
  ... 
}: 

{

  programs.waybar = {
    settings = [{
      "network#ethernet" = {
        "interface" = "enp1s0";
        "format-ethernet" = "󰌗";
        "format-disconnected" = "󰌗";
        "tooltip-format-ethernet" = "Ethernet: {ipaddr}";
        "tooltip-format-disconnected" = "Ethernet: Disconnected";
      };
    }];
  }; 

}