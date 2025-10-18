{ 
  config,
  lib,
  configLib,
  pkgs, 
  ... 
}: 

{

  wayland.windowManager.hyprland = {
    settings = {
      bind = [
        "$mod, F8, exec, rfkill toggle wlan"
      ];
      bindl = [
        ", switch:on:Lid Switch,exec,hyprctl keyword monitor desc:Chimei Innolux Corporation 0x14D4, disable" # when laptop lid is closed, disable laptop screen
        ", switch:off:Lid Switch,exec,hyprctl keyword monitor desc:Chimei Innolux Corporation 0x14D4, 1920x1080@60, auto-right, 1" # when laptop lid is open, enable laptop screen and put it to the right of 32" external monitor
      ];
      monitor = [
        "desc:ASUSTek COMPUTER INC ASUS VG32V 0x0001618C, 2560x1440@100, 0x0, 1" # main 32" monitor
        "desc:Chimei Innolux Corporation 0x14D4, 1920x1080@60, auto-right, 1" # laptop screen
      ];
    };
  };

  programs.waybar = {
    settings = [{
      "modules-right" = [
        "battery"
        "backlight"
        "network#wifi"
        "network#ethernet"
        "network#ethernet-dock"
      ];
      "network#wifi" = {
        "interface" = "wlan0";
        "format-wifi" = "{signalStrength}% ";
        "format-disconnected" = "󰖪";
        "tooltip-format-wifi" = "Wifi: {essid} {ipaddr}";
        "tooltip-format-disconnected" = "Wifi: Disconnected";
      };
      "network#ethernet" = {
        "interface" = "enp0s31f6";
        "format-ethernet" = "󰌗";
        "format-disconnected" = "󰌗";
        "tooltip-format-ethernet" = "Ethernet: {ipaddr}";
        "tooltip-format-disconnected" = "Ethernet: Disconnected";
      };
      "network#ethernet-dock" = {
        "interface" = "enp0s20f0u2u1u2";
        "format-ethernet" = "󰌗";
        "format-disconnected" = "󰌗";
        "tooltip-format-ethernet" = "Ethernet-Dock: {ipaddr}";
        "tooltip-format-disconnected" = "Ethernet-Dock: Disconnected";
      };
      "battery" = {
	      "interval" = 30;
        "states" = {
          "good" = 90;
          "warning" = 30;
          "critical" = 5;
        };
        "format" = "{capacity}% {icon}";
        "format-charging" = "{capacity}% 󱠵";
        "format-plugged" = "{capacity}% ";
        "format-icons" = [" " " " " " " " " "];
      };
      "backlight" = {
        "device" = "intel_backlight";
        "format" = "{percent}% {icon}";
        "format-icons" = ["󰛨"];
      };
    }];
    style = 
    ''
      #battery {
          color: #ffffff;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      #battery.charging, #battery.plugged {
          color: #ffffff;
      }
      @keyframes blink {
          to {
              background-color: #ffffff;
              color: #000000;
          }
      }
      #battery.critical:not(.charging) {
          background-color: #f53c3c;
          color: #ffffff;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
      }
      label:focus {
          background-color: #000000;
      }
      #backlight {
          color: #ffffff;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
    ''; 
  };

}