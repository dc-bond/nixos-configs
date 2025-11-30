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
        "pulseaudio"
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
        "format" = "{temperatureF}°F ";
        "tooltip-format" = "CPU Temperature";
        "critical-threshold" = 176;
        "format-critical" = "{temperatureF}°F ";
      };
      
      "cpu" = {
        "format" = "{usage}% ";
        "tooltip-format" = "CPU Usage";
      };
      
      "memory" = {
        "format" = "{percentage}% 󰘚";
        "tooltip-format" = "RAM Usage";
      };
      
      "disk" = {
        "interval" = 10;
        "format" = "{percentage_used}% ";
        "tooltip-format" = "Disk Space Used";
        "path" = "/";
      };

      "pulseaudio" = {
        "format" = "{icon}";
        "format-muted" = "󰖁";
        "format-icons" = {
          "default" = [ 
            "" 
            "" 
            "" 
          ];
        };
        "on-click" = "pwvucontrol";
        "tooltip-format" = "Volume: {volume}%";
      };

      "bluetooth" = {
        "format" = "";
        "format-connected" = "";
        "format-off" = "󰂲";
        "format-disabled" = "󰂲";
        "tooltip-format" = "Bluetooth";
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
        "on-click" = "alacritty -e tstat"; # run 'tailscale status' on click
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
        "on-click" = "alacritty -e ip a"; # run 'ip a' on click
      };

      "network#ethernet" = {
        "interface" = hostData.networking.ethernetInterface;
        "format-ethernet" = "󰌗";
        "format-disconnected" = "󰌗";
        "tooltip-format-ethernet" = "Ethernet: {ipaddr}";
        "tooltip-format-disconnected" = "Ethernet: Disconnected";
        "on-click" = "alacritty -e ip a"; # run 'ip a' on click
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
          font-size: 14px;
      }
      
      window#waybar {
          background: rgba(0, 0, 0, 0.85);
          transition-property: background-color;
          transition-duration: .5s;
          border-top: 2px solid @color11;
      }
      
      tooltip {
          background: linear-gradient(135deg, @color11 0%, @color1 100%);
          border: 2px solid @color11;
          border-radius: 12px;
          opacity: 0.95;
          padding: 12px 16px;
          margin: 0px;
          box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5);
      }
      
      tooltip label {
          color: #ffffff;
          font-weight: 600;
      }
      
      .modules-left > widget:first-child > #workspaces {
          margin-left: 8px;
      }
      
      .modules-right > widget:last-child > #workspaces {
          margin-right: 8px;
      }

      #workspaces button {
          color: @color11;
          background: rgba(255, 255, 255, 0.05);
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
          border-radius: 12px;
          padding: 4px 12px;
          margin: 4px 3px;
          border: 2px solid transparent;
      }
      
      #workspaces button.active {
          color: #000000;
          background: linear-gradient(135deg, @color11 0%, @color1 100%);
          border: 2px solid @color11;
          box-shadow: 0 2px 10px rgba(255, 255, 255, 0.3);
      }
      
      #workspaces button:hover {
          color: #ffffff;
          background: @color1;
          border: 2px solid @color1;
      }
      
      #taskbar button {
          color: @color11;
          background: rgba(255, 255, 255, 0.05);
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
          border-radius: 12px;
          padding: 4px 12px;
          margin: 4px 3px;
          border: 2px solid transparent;
      }
      
      #taskbar button.active {
          color: #000000;
          background: linear-gradient(135deg, @color11 0%, @color1 100%);
          border: 2px solid @color11;
          box-shadow: 0 2px 10px rgba(255, 255, 255, 0.3);
      }
      
      #taskbar button:hover {
          color: #ffffff;
          background: @color1;
          border: 2px solid @color1;
      }
      
      #tray,
      #battery,
      #backlight,
      #temperature,
      #cpu,
      #memory,
      #disk,
      #pulseaudio,
      #bluetooth,
      #network,
      #clock {
          color: #ffffff;
          background: linear-gradient(135deg, rgba(255, 255, 255, 0.08) 0%, rgba(255, 255, 255, 0.04) 100%);
          padding: 4px 14px;
          margin: 4px 4px;
          border-radius: 12px;
          border: 1px solid rgba(255, 255, 255, 0.1);
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }
      
      #tray:hover,
      #battery:hover,
      #backlight:hover,
      #temperature:hover,
      #cpu:hover,
      #memory:hover,
      #disk:hover,
      #pulseaudio:hover,
      #bluetooth:hover,
      #network:hover {
          background: linear-gradient(135deg, @color11 0%, @color1 100%);
          border: 1px solid @color11;
          box-shadow: 0 2px 8px rgba(255, 255, 255, 0.2);
      }
      
      #battery.charging, #battery.plugged {
          color: #00ff00;
          background: linear-gradient(135deg, rgba(0, 255, 0, 0.15) 0%, rgba(0, 255, 0, 0.05) 100%);
          border: 1px solid rgba(0, 255, 0, 0.3);
      }
      
      #battery.warning:not(.charging) {
          color: #ffcc00;
          background: linear-gradient(135deg, rgba(255, 204, 0, 0.15) 0%, rgba(255, 204, 0, 0.05) 100%);
          border: 1px solid rgba(255, 204, 0, 0.3);
      }
      
      #battery.critical:not(.charging) {
          color: #ff0000;
          background: linear-gradient(135deg, #f53c3c 0%, #c41e1e 100%);
          border: 1px solid #ff0000;
          animation-name: blink;
          animation-duration: 1s;
          animation-timing-function: ease-in-out;
          animation-iteration-count: infinite;
          animation-direction: alternate;
      }
      
      @keyframes blink {
          to {
              background: linear-gradient(135deg, #ff6b6b 0%, #f53c3c 100%);
              box-shadow: 0 2px 12px rgba(255, 0, 0, 0.5);
          }
      }
      
      #temperature.critical {
          color: #ff0000;
          background: linear-gradient(135deg, #ff3131 0%, #c41e1e 100%);
          border: 1px solid #ff0000;
          box-shadow: 0 2px 8px rgba(255, 0, 0, 0.3);
      }

      #pulseaudio {
          color: #00ff00;
          background: linear-gradient(135deg, rgba(0, 255, 0, 0.15) 0%, rgba(0, 255, 0, 0.05) 100%);
          padding: 4px 14px;
          margin: 4px 4px;
          border-radius: 12px;
          border: 1px solid rgba(0, 255, 0, 0.3);
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }
      
      #pulseaudio:hover {
          background: linear-gradient(135deg, @color11 0%, @color1 100%);
          border: 1px solid @color11;
          box-shadow: 0 2px 8px rgba(255, 255, 255, 0.2);
      }
      
      #pulseaudio.muted {
          color: #77767b;
          background: linear-gradient(135deg, rgba(119, 118, 123, 0.08) 0%, rgba(119, 118, 123, 0.04) 100%);
          border: 1px solid rgba(119, 118, 123, 0.2);
      }

      #bluetooth.on {
          color: #ffffff;
      }
      
      #bluetooth.connected {
          color: #00ff00;
          background: linear-gradient(135deg, rgba(0, 255, 0, 0.15) 0%, rgba(0, 255, 0, 0.05) 100%);
          border: 1px solid rgba(0, 255, 0, 0.3);
      }
      
      #bluetooth.off,
      #bluetooth.disabled {
          color: #77767b;
          background: linear-gradient(135deg, rgba(119, 118, 123, 0.08) 0%, rgba(119, 118, 123, 0.04) 100%);
          border: 1px solid rgba(119, 118, 123, 0.2);
      }
      
      #network {
          color: #00ff00;
          background: linear-gradient(135deg, rgba(0, 255, 0, 0.15) 0%, rgba(0, 255, 0, 0.05) 100%);
          border: 1px solid rgba(0, 255, 0, 0.3);
      }
      
      #network.disconnected,
      #network.disabled,
      #network.linked {
          color: #77767b;
          background: linear-gradient(135deg, rgba(119, 118, 123, 0.08) 0%, rgba(119, 118, 123, 0.04) 100%);
          border: 1px solid rgba(119, 118, 123, 0.2);
      }
      
      #clock {
          color: #ffffff;
          background: linear-gradient(135deg, @color11 0%, @color1 100%);
          border: 2px solid @color11;
          padding: 4px 16px;
          margin: 4px 8px 4px 4px;
          font-weight: 600;
          box-shadow: 0 2px 10px rgba(255, 255, 255, 0.2);
      }
      
      #clock:hover {
          box-shadow: 0 4px 16px rgba(255, 255, 255, 0.3);
      }
      
      label:focus {
          background-color: transparent;
      }
    '';

  };

}