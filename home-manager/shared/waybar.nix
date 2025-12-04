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
      enable = true;
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
        "custom/weather"
        "memory"
        "disk"
        "cpu"
        "temperature"
        "custom/public-ip"
        "backlight"
        "battery"
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
        "custom/hostname"
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

      "custom/weather" = {
        "format" = "{} ";
        "interval" = 1800;  # update every 30 minutes
        "exec" = "${pkgs.curl}/bin/curl -s --max-time 5 'wttr.in/?format=%c+%t' || echo '?'";
        "return-type" = "";
        "on-click" = "${pkgs.alacritty}/bin/alacritty -e zsh -c 'curl wttr.in; read -k 1 \"?Press any key to continue...\"; exec zsh'";
        "tooltip-format" = "Outside Weather";
      };
      
      "memory" = {
        "format" = "{percentage}% 󰘚";
        "tooltip-format" = "RAM Usage";
        "on-click" = "${pkgs.alacritty}/bin/alacritty -e ${pkgs.btop}/bin/btop";
      };
      
      "disk" = {
        "interval" = 10;
        "format" = "{percentage_used}% ";
        "tooltip-format" = "Disk Space Used";
        "path" = "/";
        "on-click" = "${pkgs.alacritty}/bin/alacritty -e ${pkgs.ncdu}/bin/ncdu /";
      };

      "cpu" = {
        "format" = "{usage}% ";
        "tooltip-format" = "CPU Usage";
        "on-click" = "${pkgs.alacritty}/bin/alacritty -e ${pkgs.btop}/bin/btop";
      };

      "temperature" = {
        "format" = "{temperatureF}°F ";
        "tooltip-format" = "CPU Temperature";
        "thermal-zone" = 2;
        "critical-threshold" = 176;
        "format-critical" = "{temperatureF}°F ";
        "on-click" = "${pkgs.alacritty}/bin/alacritty -e ${pkgs.btop}/bin/btop";
        "interval" = 5;
      };

      "custom/public-ip" = {
        "format" = " {}";
        "interval" = 60;  # update every minute
        "exec" = "${pkgs.curl}/bin/curl -s --max-time 5 ifconfig.io || echo '?.?.?.?'";
        "return-type" = "";
        "tooltip-format" = "Public IPv4 WAN Address";
        "on-click" = "xdg-open https://ipleak.net";
      };

      "backlight" = {
        "device" = "intel_backlight";
        "format" = "{percent}% {icon}";
        "format-icons" = ["󰛨"];
        "tooltip-format" = "Screen Brightness: {percent}%";
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
        "format-plugged" = "{capacity}% {icon}";
        "format-icons" = [
          ""
          "" 
          "" 
          "" 
          "" 
        ];
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
        "on-click" = "${pkgs.pwvucontrol}/bin/pwvucontrol";
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
        "on-click" = "${pkgs.alacritty}/bin/alacritty -e ${pkgs.bluez}/bin/bluetoothctl";
        "interval" = 5;
      };
      
      "network#tailscale" = {
        "interface" = "tailscale0";
        "format" = "󰴳";
        "format-disconnected" = "󰦞";
        "format-linked" = "󰦞";
        "tooltip-format" = "Tailscale IPv4 Private VPN Address: {ipaddr}";
        "tooltip-format-disconnected" = "Tailscale: Disconnected";
        "on-click" = "${pkgs.alacritty}/bin/alacritty -e zsh -c 'sudo ${pkgs.tailscale}/bin/tailscale up --ssh --accept-routes --reset && ${pkgs.tailscale}/bin/tailscale status; echo; read -k 1 \"?Press any key to continue...\"; exec zsh'";
      };
    
      "network#wifi" = {
        "interface" = hostData.networking.wifiInterface;
        "format-wifi" = "{icon}  {signalStrength}%";
        "format-disconnected" = "{icon}";
        "format-icons" = {
          "wifi" =  "";
          "disconnected" = "";
        };
        "tooltip-format-wifi" = "{essid} IPv4 Wifi Address: {ipaddr} - Signal Strength: {signalStrength}%";
        "tooltip-format-disconnected" = "Wifi: Disconnected";
        "on-click" = "${pkgs.alacritty}/bin/alacritty -e wifi"; # run wifi helper script on click
      };

      "network#ethernet-dock" = {
        "interface" = hostData.networking.dockInterface;
        "format-ethernet" = "󰌗";
        "format-disconnected" = "󰌗";
        "tooltip-format-ethernet" = "Ethernet-Dock IPv4 Private LAN Address: {ipaddr}";
        "tooltip-format-disconnected" = "Ethernet-Dock: Disconnected";
        "on-click" = "${pkgs.alacritty}/bin/alacritty -e zsh -c 'echo \"Your external public IPv4 address is:\"; ${pkgs.curl}/bin/curl ifconfig.io; echo; ${pkgs.speedtest-rs}/bin/speedtest-rs; echo; read -k 1 \"?Press any key to continue...\"; exec zsh'";
      };

      "network#ethernet" = {
        "interface" = hostData.networking.ethernetInterface;
        "format-ethernet" = "󰌗";
        "format-disconnected" = "󰌗";
        "tooltip-format-ethernet" = "Ethernet IPv4 Private LAN Address: {ipaddr}";
        "tooltip-format-disconnected" = "Ethernet: Disconnected";
        "on-click" = "${pkgs.alacritty}/bin/alacritty -e zsh -c 'echo \"Your external public IPv4 address is:\"; ${pkgs.curl}/bin/curl ifconfig.io; echo; ${pkgs.speedtest-rs}/bin/speedtest-rs; echo; read -k 1 \"?Press any key to continue...\"; exec zsh'";
      };

      "custom/hostname" = {
        "format" = "{}";
        "exec" = "echo $USER@${osConfig.networking.hostName}";
        "interval" = "once";
        "tooltip-format" = "user@hostname";
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
      
      /* ===== WORKSPACES & TASKBAR ===== */
      
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
      
      /* ===== STANDARD MODULES (White/Grey) ===== */
      
      #tray,
      #temperature,
      #cpu,
      #memory,
      #disk,
      #custom-public-ip {
          color: #ffffff;
          background: linear-gradient(135deg, rgba(255, 255, 255, 0.08) 0%, rgba(255, 255, 255, 0.04) 100%);
          padding: 4px 14px;
          margin: 4px 4px;
          border-radius: 12px;
          border: 1px solid rgba(255, 255, 255, 0.1);
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }
      
      #tray:hover,
      #temperature:hover,
      #cpu:hover,
      #memory:hover,
      #disk:hover,
      #custom-public-ip:hover {
          background: linear-gradient(135deg, @color11 0%, @color1 100%);
          border: 1px solid @color11;
          box-shadow: 0 2px 8px rgba(255, 255, 255, 0.2);
      }
      
      /* ===== WEATHER MODULE (Sky Blue) ===== */
      
      #custom-weather {
          color: #87ceeb;
          background: linear-gradient(135deg, rgba(135, 206, 235, 0.15) 0%, rgba(135, 206, 235, 0.05) 100%);
          padding: 4px 14px;
          margin: 4px 4px;
          border-radius: 12px;
          border: 1px solid rgba(135, 206, 235, 0.3);
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }
      
      #custom-weather:hover {
          background: linear-gradient(135deg, @color11 0%, @color1 100%);
          border: 1px solid @color11;
          box-shadow: 0 2px 8px rgba(255, 255, 255, 0.2);
      }

      /* ===== BACKLIGHT ===== */

      #backlight {
          color: #00ff00;
          background: linear-gradient(135deg, rgba(0, 255, 0, 0.15) 0%, rgba(0, 255, 0, 0.05) 100%);
          padding: 4px 14px;
          margin: 4px 4px;
          border-radius: 12px;
          border: 1px solid rgba(0, 255, 0, 0.3);
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }
      
      #backlight:hover {
          background: linear-gradient(135deg, @color11 0%, @color1 100%);
          border: 1px solid @color11;
          box-shadow: 0 2px 8px rgba(255, 255, 255, 0.2);
      }
      
      /* ===== BATTERY ===== */
      
      #battery {
          color: #00ff00;
          background: linear-gradient(135deg, rgba(0, 255, 0, 0.15) 0%, rgba(0, 255, 0, 0.05) 100%);
          padding: 4px 14px;
          margin: 4px 4px;
          border-radius: 12px;
          border: 1px solid rgba(0, 255, 0, 0.3);
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }
      
      #battery:hover {
          background: linear-gradient(135deg, @color11 0%, @color1 100%);
          border: 1px solid @color11;
          box-shadow: 0 2px 8px rgba(255, 255, 255, 0.2);
      }
      
      #battery.charging,
      #battery.plugged {
          color: #00ff00;
          background: linear-gradient(135deg, rgba(0, 255, 0, 0.15) 0%, rgba(0, 255, 0, 0.05) 100%);
          border: 1px solid rgba(0, 255, 0, 0.3);
      }
      
      #battery.warning:not(.charging) {
          color: #ffcc00;
          background: linear-gradient(135deg, rgba(255, 204, 0, 0.15) 0%, rgba(255, 204, 0, 0.05) 100%);
          border: 1px solid rgba(255, 204, 0, 0.3);
      }
      
      #battery.warning:not(.charging):hover {
          background: linear-gradient(135deg, @color11 0%, @color1 100%);
          border: 1px solid @color11;
          box-shadow: 0 2px 8px rgba(255, 255, 255, 0.2);
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
      
      #battery.critical:not(.charging):hover {
          background: linear-gradient(135deg, @color11 0%, @color1 100%);
          border: 1px solid @color11;
          box-shadow: 0 2px 8px rgba(255, 255, 255, 0.2);
          animation: none;
      }
      
      @keyframes blink {
          to {
              background: linear-gradient(135deg, #ff6b6b 0%, #f53c3c 100%);
              box-shadow: 0 2px 12px rgba(255, 0, 0, 0.5);
          }
      }

      /* ===== BLUETOOTH ===== */

      #bluetooth {
          color: #ffffff;
          background: linear-gradient(135deg, rgba(255, 255, 255, 0.08) 0%, rgba(255, 255, 255, 0.04) 100%);
          padding: 4px 14px;
          margin: 4px 4px;
          border-radius: 12px;
          border: 1px solid rgba(255, 255, 255, 0.1);
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }
      
      #bluetooth:hover {
          background: linear-gradient(135deg, @color11 0%, @color1 100%);
          border: 1px solid @color11;
          box-shadow: 0 2px 8px rgba(255, 255, 255, 0.2);
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
      
      /* ===== NETWORK ===== */
      
      #network {
          color: #00ff00;
          background: linear-gradient(135deg, rgba(0, 255, 0, 0.15) 0%, rgba(0, 255, 0, 0.05) 100%);
          padding: 4px 14px;
          margin: 4px 4px;
          border-radius: 12px;
          border: 1px solid rgba(0, 255, 0, 0.3);
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      }
      
      #network:hover {
          background: linear-gradient(135deg, @color11 0%, @color1 100%);
          border: 1px solid @color11;
          box-shadow: 0 2px 8px rgba(255, 255, 255, 0.2);
      }
      
      #network.disconnected,
      #network.disabled,
      #network.linked {
          color: #77767b;
          background: linear-gradient(135deg, rgba(119, 118, 123, 0.08) 0%, rgba(119, 118, 123, 0.04) 100%);
          border: 1px solid rgba(119, 118, 123, 0.2);
      }
      
      /* ===== PULSEAUDIO ===== */
      
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

      /* ===== TEMPERATURE STATES ===== */
      
      #temperature.critical {
          color: #ffffff;
          background: linear-gradient(135deg, #ff3131 0%, #c41e1e 100%);
          border: 1px solid #ff0000;
          box-shadow: 0 2px 8px rgba(255, 0, 0, 0.3);
      }

      /* ===== BATTERY STATES ===== */
  
      #battery.charging,
      #battery.plugged {
          color: #00ff00;
          background: linear-gradient(135deg, rgba(0, 255, 0, 0.15) 0%, rgba(0, 255, 0, 0.05) 100%);
          border: 1px solid rgba(0, 255, 0, 0.3);
      }
      
      #battery.charging:hover,
      #battery.plugged:hover {
          background: linear-gradient(135deg, @color11 0%, @color1 100%);
          border: 1px solid @color11;
          box-shadow: 0 2px 8px rgba(255, 255, 255, 0.2);
      }
      
      #battery.warning:not(.charging) {
          color: #ffcc00;
          background: linear-gradient(135deg, rgba(255, 204, 0, 0.15) 0%, rgba(255, 204, 0, 0.05) 100%);
          border: 1px solid rgba(255, 204, 0, 0.3);
      }
      
      #battery.warning:not(.charging):hover {
          background: linear-gradient(135deg, @color11 0%, @color1 100%);
          border: 1px solid @color11;
          box-shadow: 0 2px 8px rgba(255, 255, 255, 0.2);
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
      
      #battery.critical:not(.charging):hover {
          background: linear-gradient(135deg, @color11 0%, @color1 100%);
          border: 1px solid @color11;
          box-shadow: 0 2px 8px rgba(255, 255, 255, 0.2);
          animation: none;
      }

      @keyframes blink {
          to {
              background: linear-gradient(135deg, #ff6b6b 0%, #f53c3c 100%);
              box-shadow: 0 2px 12px rgba(255, 0, 0, 0.5);
          }
      } 
      
      /* ===== HOSTNAME & CLOCK MODULES (Accent) ===== */
      
      #custom-hostname,
      #clock {
          color: #ffffff;
          background: linear-gradient(135deg, @color11 0%, @color1 100%);
          border: 2px solid @color11;
          padding: 4px 16px;
          margin: 4px 8px 4px 4px;
          border-radius: 12px;
          font-weight: 600;
          box-shadow: 0 2px 10px rgba(255, 255, 255, 0.2);
      }
      
      #custom-hostname:hover,
      #clock:hover {
          box-shadow: 0 4px 16px rgba(255, 255, 255, 0.3);
      }
      
      label:focus {
          background-color: transparent;
      }
    ''; 

  };

}