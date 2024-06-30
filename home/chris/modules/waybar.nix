{ config, pkgs, ... }: 

{

  programs.waybar = {
    enable = true;
    systemd = {
      enable = false;
      target = "graphical-session.target";
    };
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
        "network#wireguard"
        "network#wifi"
        "network#ethernet"
        "network#ethernet-dock"
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
      "network#wireguard" = {
        "interface" = "wg0";
        "format" = "󰴳";
        "format-disconnected" = "󰴳";
        #"format-disconnected" = "󰦞";
        "tooltip-format" = "Wireguard: {ipaddr}";
        "tooltip-format-disconnected" = "Wireguard: Disconnected";
      };
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
    style = 
    ''
      @import 'colors-waybar.css';
      * {
          font-family: SauceCodePro Nerd Font;
          border: none;
          min-height: 0;
      }
      window#waybar {
          background: #000000;
          transition-property: background-color;
          transition-duration: .5s;
      }
      #workspaces button {
          color: @color11;
          transition: all 0.3s ease-in-out;
          opacity: 0.8;
          border-radius: 20px;
          font-size: 14px;
      }
      #workspaces button.active {
          color: #ffffff;
          background-color: @color11;
          transition: all 0.3s ease-in-out;
          border-radius: 20px;
          opacity: 1.0;
      }
      #workspaces button:hover {
          color: #ffffff;
          background-color: @color1;
      }
      tooltip {
          background-color: #ffffff;
          border-radius: 10px;
          opacity: 0.8;
          padding: 20px;
          margin: 0px;
      }
      tooltip label {
          color: @color11;
      }
      .modules-left > widget:first-child > #workspaces {
          margin-left: 0;
      }
      .modules-right > widget:last-child > #workspaces {
          margin-right: 0;
      }
      #temperature {
          color: #ffffff;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      #temperature.critical {
          color: #ff3131;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      #cpu {
          color: #ffffff;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      #memory {
          color: #ffffff;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      #disk {
          color: #ffffff;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      #clock {
          font-size: 14px;
          color: #ffffff;
          padding: 1px 10px 1px 10px;
      }
      #network.wireguard {
          color: #00ff00;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      #network.wifi {
          color: #00ff00;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      #network.ethernet {
          color: #00ff00;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      #network.ethernet-dock {
          color: #00ff00;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      #network.disconnected {
          color: #77767b;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      #network.disabled {
          color: #77767b;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      #bluetooth.on {
          color: #ffffff;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      #bluetooth.connected {
          color: #00ff00;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      #bluetooth.off {
          color: #77767b;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      #bluetooth.disabled {
          color: #77767b;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
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