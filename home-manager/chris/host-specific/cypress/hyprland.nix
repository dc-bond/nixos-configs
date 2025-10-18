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
      "modules-right" = lib.mkAfter [
        "network#ethernet"
      ];
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