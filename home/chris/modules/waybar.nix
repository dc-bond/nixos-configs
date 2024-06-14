{ config, pkgs, ... }: 

{

  programs.waybar = {
    enable = true;
    systemd = {
      enable = false;
      target = "graphical-session.target";
    };
    #style = ''
    #  #@import 'colors-waybar.css';
    #  * {
    #    font-family: SauceCodePro Nerd Font;
    #    border: none;
    #    min-height: 0;
    #  }
    #'';
    settings = [{
      "position" = "bottom";
      "layer" = "top";
      "margin-bottom" = 0;
      "margin-top" = 0;
      "margin-left" = 0;
      "margin-right" = 0;
      "modules-left" = [
        "hyprland/workspaces"
      ];
      "modules-right" = [
	      "temperature"
	      "backlight" # not working
	      "cpu"
	      "memory"
	      "disk"
        #"pulseaudio",
        "battery"
        "bluetooth"
        "network#vpn"
        "network#wifi"
        "network#wired"
        "network#wired-dock"
        "clock"
      ];
      "hyprland/workspaces" = {
        "format" = "{icon}";
        "tooltip" = false;
        "all-outputs" = false;
        "current-only" = false;
        "sort-by-number" = true;
        "format-icons" = {
          "1" = "1";
          "2" = "2";
          "3" = "3";
          "4" = "4";
          "5" = "5";
          "6" = "6";
          "7" = "7";
          "8" = "8";
          "9" = "9";
          "10" = "10";
        };
      };
      "clock" = {
        "timezone" = "America/New_York";
	      "format" = "{:%I:%M}";
      };
      "cpu" = {
        "format" = "{usage}% ";
      };
      "memory" = {
        "format" = "{percentage}% 󰘚";
      };
      "disk" = {
        "interval" = 10;
        "format" = "{percentage_used}% ";
        "path" = "/";
      };
      "temperature" = {
	      "critical-threshold" = 80;
	      "format-critical" = "{temperatureC}°C ";
	      "format" = "{temperatureC}°C ";
      };
      "network#vpn" = {
        "interface" = "wg0";
        "format" = "󰴳";
        "format-disconnected" = "󰦞";
        "tooltip-format" = "VPN: {ipaddr}";
        "tooltip-format-disabled" = "VPN: Disconnected";
      };
      "network#wifi" = {
        "interface" = "wlan0";
        "format-wifi" = "{signalStrength}% ";
        "format-disconnected" = "󰖪";
        "tooltip-format-wifi" = "Wifi: {essid} {ipaddr}";
        "tooltip-format-disconnected" = "Wifi: Disconnected";
      };
      "network#wired" = {
        "interface" = "enp0s31f6";
        "format-ethernet" = "󰌗";
        "format-disconnected" = "󰌗";
        "tooltip-format-ethernet" = "Wired: {ipaddr}";
        "tooltip-format-disconnected" = "Wired: Disconnected";
      };
      "network#wired-dock" = {
        "interface" = "enp0s20f0u2u1u2";
        "format-ethernet" = "󰌗";
        "format-disconnected" = "󰌗";
        "tooltip-format-ethernet" = "Wired-Dock: {ipaddr}";
        "tooltip-format-disconnected" = "Wired-Dock: Disconnected";
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
      #"pulseaudio": {
      #  "scroll-step": 1,
      #  "format": "{icon}{volume}%",
      #  "format-bluetooth": "{volume}% {icon}  {format_source}",
      #  "format-bluetooth-muted": "{icon}  {format_source}",
      #  "format-muted": "{format_source} ",
      #  "format-source": "{volume}% ",
      #  "format-source-muted": "",
      #  "format-icons": {
      #    "headphone": "",
      #    "hands-free": "",
      #    "headset": "",
      #    "phone": "",
      #    "portable": "",
      #    "car": "",
      #    "default": [" ", " ", " "]
      #  },
      #  "on-click": "pavucontrol"
      #},
      "bluetooth" = {
	      "format" = "";
	      "format-connected" = " {num_connections}";
	      "format-off" = "";
        "format-disabled" = "󰂲";
        "interval" = 5;
        "on-click" = "blueman-manager";
      };
      "backlight" = {
        "device" = "intel_backlight";
        "format" = "{percent}% {icon}";
        "format-icons" = ["󰛨"];
      };
    }];
  };

}