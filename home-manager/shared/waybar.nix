{ 
  config, 
  lib, 
  pkgs, 
  configVars,
  osConfig,
  ... 
}: 

let
  hostData = configVars.hosts.${osConfig.networking.hostName};
  wm = hostData.windowManager;
  hasWifi = hostData.networking.wifiInterface != null;
  hasDock = hostData.networking.dockInterface != null;
  hasEthernet = hostData.networking.ethernetInterface != null;
in

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
      
      "modules-left" = 
        if wm == "hyprland" then [ "hyprland/workspaces" ]
        else if wm == "labwc" then [ 
          "custom/launcher"
          "wlr/taskbar" 
        ]
        else [];
      
      "modules-right" = [
        "tray"
        "battery"
        "backlight"
        "temperature"
        "cpu"
        "memory"
        "disk"
        "bluetooth"
        "network#tailscale"
      ] ++ lib.optionals hasWifi [
        "network#wifi"
      ] ++ lib.optionals hasDock [
        "network#ethernet-dock"
      ] ++ lib.optionals hasEthernet [
        "network#ethernet"
      ] ++ [
        "clock"
      ];

      "custom/launcher" = {
        "format" = "";
        "on-click" = "nwg-menu";
        "tooltip" = false;
      };

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

      "wlr/taskbar" = {
        "format" = "{icon}";
        "icon-size" = 18;
        "icon-theme" = "Papirus";
        "tooltip-format" = "{title}";
        "on-click" = "minimize-raise";
        "on-click-middle" = "close";
        "ignore-list" = [];
      };
      
      "tray" = {
        "icon_size" = 18;
        "spacing" = 15;
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
        "format-plugged" = "{capacity}% ";
        "format-icons" = [" " " " " " " " " "];
      };

      "backlight" = {
        "device" = "intel_backlight";
        "format" = "{percent}% {icon}";
        "format-icons" = ["󰛨"];
      };

      "temperature" = {
        "critical-threshold" = 80;
        "format-critical" = "{temperatureC}°C ";
        "format" = "{temperatureC}°C ";
      };
      
      "cpu" = {
        "format" = "{usage}% ";
      };
      
      "memory" = {
        "format" = "{percentage}% 󰘚";
      };
      
      "disk" = {
        "interval" = 10;
        "format" = "{percentage_used}% ";
        "path" = "/";
      };

      "bluetooth" = {
        "format" = "";
        "format-connected" = "";
        "format-off" = "󰂲";
        "format-disabled" = "󰂲";
        "tooltip-format" = "Bluetooth: {status}";
        "tooltip-format-connected" = "Bluetooth: {device_enumerate}";
        "tooltip-format-enumerate-connected" = "{device_alias}";
        "interval" = 5;
      };
      
      "network#tailscale" = {
        "interface" = "tailscale0";
        "format" = "󰴳";
        "format-disconnected" = "󰦞";
        "format-linked" = "󰦞";
        "tooltip-format" = "Tailscale: {ipaddr}";
        "tooltip-format-disconnected" = "Tailscale: Disconnected";
      };
    
      "network#wifi" = {
        "interface" = hostData.networking.wifiInterface;
        "format-wifi" = "";
        "format-disconnected" = "󰖪";
        "tooltip-format-wifi" = "{essid}: {signalStrength}% ({ipaddr})";
        "tooltip-format-disconnected" = "Wifi: Disconnected";
        "on-click" = "alacritty -e wifi"; # run wifi helper script on click
      };

      "network#ethernet-dock" = {
        "interface" = hostData.networking.dockInterface;
        "format-ethernet" = "󰌗";
        "format-disconnected" = "󰌗";
        "tooltip-format-ethernet" = "Ethernet-Dock: {ipaddr}";
        "tooltip-format-disconnected" = "Ethernet-Dock: Disconnected";
      };

      "network#ethernet" = {
        "interface" = hostData.networking.ethernetInterface;
        "format-ethernet" = "󰌗";
        "format-disconnected" = "󰌗";
        "tooltip-format-ethernet" = "Ethernet: {ipaddr}";
        "tooltip-format-disconnected" = "Ethernet: Disconnected";
      };

      "clock" = {
        "timezone" = "America/New_York";
        "format" = "{:%I:%M}";
        "tooltip-format" = "{:%A, %B %d, %Y}";
      };

    }];
    
    style = ''
      @import 'colors-waybar.css';
      
      * {
          font-family: "SauceCodePro Nerd Font", "Font Awesome 6 Free";
          border: none;
          min-height: 0;
      }
      
      window#waybar {
          background: #000000;
          transition-property: background-color;
          transition-duration: .5s;
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

      #custom-launcher {
        font-size: 20px;
        color: #ffffff;
        padding: 0 15px;
      }
      
      #custom-launcher:hover {
        background-color: @color1;
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
      
      #taskbar button {
          color: @color11;
          transition: all 0.3s ease-in-out;
          opacity: 0.8;
          border-radius: 20px;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      
      #taskbar button.active {
          color: #ffffff;
          background-color: @color11;
          transition: all 0.3s ease-in-out;
          border-radius: 20px;
          opacity: 1.0;
      }
      
      #taskbar button:hover {
          color: #ffffff;
          background-color: @color1;
      }
      
      #tray {
          color: #ffffff;
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
      
      #battery.critical:not(.charging) {
          background-color: #f53c3c;
          color: #ffffff;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
      }
      
      @keyframes blink {
          to {
              background-color: #ffffff;
              color: #000000;
          }
      }
      
      #backlight {
          color: #ffffff;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
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
      
      #network {
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
      
      #network.linked {
          color: #77767b;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      
      #clock {
          font-size: 14px;
          color: #ffffff;
          padding: 1px 10px 1px 10px;
      }
      
      label:focus {
          background-color: #000000;
      }
    '';
  };

}