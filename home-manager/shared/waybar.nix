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
    
    #style = ''
    #  @import 'colors-waybar.css';
    #  
    #  * {
    #      font-family: "SauceCodePro Nerd Font", "Font Awesome 6 Free";
    #      border: none;
    #      min-height: 0;
    #  }
    #  
    #  window#waybar {
    #      background: #000000;
    #      transition-property: background-color;
    #      transition-duration: .5s;
    #  }
    #  
    #  tooltip {
    #      background-color: #ffffff;
    #      border-radius: 10px;
    #      opacity: 0.8;
    #      padding: 20px;
    #      margin: 0px;
    #  }
    #  
    #  tooltip label {
    #      color: @color11;
    #  }
    #  
    #  .modules-left > widget:first-child > #workspaces {
    #      margin-left: 0;
    #  }
    #  
    #  .modules-right > widget:last-child > #workspaces {
    #      margin-right: 0;
    #  }

    #  #workspaces button {
    #      color: @color11;
    #      transition: all 0.3s ease-in-out;
    #      opacity: 0.8;
    #      border-radius: 20px;
    #      font-size: 14px;
    #  }
    #  
    #  #workspaces button.active {
    #      color: #ffffff;
    #      background-color: @color11;
    #      transition: all 0.3s ease-in-out;
    #      border-radius: 20px;
    #      opacity: 1.0;
    #  }
    #  
    #  #workspaces button:hover {
    #      color: #ffffff;
    #      background-color: @color1;
    #  }
    #  
    #  #taskbar button {
    #      color: @color11;
    #      transition: all 0.3s ease-in-out;
    #      opacity: 0.8;
    #      border-radius: 20px;
    #      font-size: 14px;
    #      padding: 1px 10px 1px 10px;
    #  }
    #  
    #  #taskbar button.active {
    #      color: #ffffff;
    #      background-color: @color11;
    #      transition: all 0.3s ease-in-out;
    #      border-radius: 20px;
    #      opacity: 1.0;
    #  }
    #  
    #  #taskbar button:hover {
    #      color: #ffffff;
    #      background-color: @color1;
    #  }
    #  
    #  #tray {
    #      color: #ffffff;
    #      font-size: 14px;
    #      padding: 1px 10px 1px 10px;
    #  }
    #  
    #  #battery {
    #      color: #ffffff;
    #      font-size: 14px;
    #      padding: 1px 10px 1px 10px;
    #  }
    #  
    #  #battery.charging, #battery.plugged {
    #      color: #ffffff;
    #  }
    #  
    #  #battery.critical:not(.charging) {
    #      background-color: #f53c3c;
    #      color: #ffffff;
    #      animation-name: blink;
    #      animation-duration: 0.5s;
    #      animation-timing-function: linear;
    #      animation-iteration-count: infinite;
    #      animation-direction: alternate;
    #  }
    #  
    #  @keyframes blink {
    #      to {
    #          background-color: #ffffff;
    #          color: #000000;
    #      }
    #  }
    #  
    #  #backlight {
    #      color: #ffffff;
    #      font-size: 14px;
    #      padding: 1px 10px 1px 10px;
    #  }
    #  
    #  #temperature {
    #      color: #ffffff;
    #      font-size: 14px;
    #      padding: 1px 10px 1px 10px;
    #  }
    #  
    #  #temperature.critical {
    #      color: #ff3131;
    #      font-size: 14px;
    #      padding: 1px 10px 1px 10px;
    #  }
    #  
    #  #cpu {
    #      color: #ffffff;
    #      font-size: 14px;
    #      padding: 1px 10px 1px 10px;
    #  }
    #  
    #  #memory {
    #      color: #ffffff;
    #      font-size: 14px;
    #      padding: 1px 10px 1px 10px;
    #  }
    #  
    #  #disk {
    #      color: #ffffff;
    #      font-size: 14px;
    #      padding: 1px 10px 1px 10px;
    #  }
    #  
    #  #bluetooth.on {
    #      color: #ffffff;
    #      font-size: 14px;
    #      padding: 1px 10px 1px 10px;
    #  }
    #  
    #  #bluetooth.connected {
    #      color: #00ff00;
    #      font-size: 14px;
    #      padding: 1px 10px 1px 10px;
    #  }
    #  
    #  #bluetooth.off {
    #      color: #77767b;
    #      font-size: 14px;
    #      padding: 1px 10px 1px 10px;
    #  }
    #  
    #  #bluetooth.disabled {
    #      color: #77767b;
    #      font-size: 14px;
    #      padding: 1px 10px 1px 10px;
    #  }
    #  
    #  #network {
    #      color: #00ff00;
    #      font-size: 14px;
    #      padding: 1px 10px 1px 10px;
    #  }
    #  
    #  #network.disconnected {
    #      color: #77767b;
    #      font-size: 14px;
    #      padding: 1px 10px 1px 10px;
    #  }
    #  
    #  #network.disabled {
    #      color: #77767b;
    #      font-size: 14px;
    #      padding: 1px 10px 1px 10px;
    #  }
    #  
    #  #network.linked {
    #      color: #77767b;
    #      font-size: 14px;
    #      padding: 1px 10px 1px 10px;
    #  }
    #  
    #  #clock {
    #      font-size: 14px;
    #      color: #ffffff;
    #      padding: 1px 10px 1px 10px;
    #  }
    #  
    #  label:focus {
    #      background-color: #000000;
    #  }
    #'';
    
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
          backdrop-filter: blur(10px);
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

      /* Workspace styling */
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
          transform: translateY(-1px);
      }
      
      #workspaces button:hover {
          color: #ffffff;
          background: @color1;
          border: 2px solid @color1;
          transform: translateY(-1px);
      }
      
      /* Taskbar styling */
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
          transform: translateY(-1px);
      }
      
      /* Module styling - creates pill-shaped containers */
      #tray,
      #battery,
      #backlight,
      #temperature,
      #cpu,
      #memory,
      #disk,
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
      #bluetooth:hover,
      #network:hover {
          background: linear-gradient(135deg, @color11 0%, @color1 100%);
          border: 1px solid @color11;
          box-shadow: 0 2px 8px rgba(255, 255, 255, 0.2);
          transform: translateY(-1px);
      }
      
      /* Battery states */
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
          color: #ffffff;
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
      
      /* Temperature states */
      #temperature.critical {
          color: #ffffff;
          background: linear-gradient(135deg, #ff3131 0%, #c41e1e 100%);
          border: 1px solid #ff0000;
          box-shadow: 0 2px 8px rgba(255, 0, 0, 0.3);
      }
      
      /* Bluetooth states */
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
      
      /* Network states */
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
      
      /* Clock styling - make it stand out */
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
          transform: translateY(-1px);
      }
      
      label:focus {
          background-color: transparent;
      }
    '';

  };

}