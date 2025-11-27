{ 
  inputs, 
  config,
  lib,
  configLib,
  pkgs, 
  osConfig,
  ... 
}: 

let
  username = builtins.baseNameOf ./.;
  wallpaperDir = pkgs.runCommand "wallpapers" {} ''
    mkdir -p $out
    cp -r ${inputs.self}/wallpaper/* $out/
  '';
  desktopReloadScript = pkgs.writeShellScriptBin "desktopReload" ''
    # select random wallpaper and create color scheme
    wal -s -t -q -i ${wallpaperDir}
    
    # load current pywal color scheme
    source "$HOME/.cache/wal/colors.sh"
    
    # copy color file to waybar folder
    cp ~/.cache/wal/colors-waybar.css ~/.config/waybar/
    cp $wallpaper ~/.cache/current_wallpaper.jpg
    
    # get wallpaper image name
    newwall=$(echo $wallpaper | sed "s|~/nixos-configs/wallpaper/||g")
    
    # set the new wallpaper
    swww img $wallpaper --transition-step 20 --transition-fps=20
    
    # reload waybar
    pkill waybar
    waybar &
    
    # send notification
    dunstify "wallpaper updated with image $newwall"
  '';
in

{

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "home-manager/${username}/alacritty.nix"
      "home-manager/${username}/gammastep.nix"
      "home-manager/${username}/firefox.nix"
      "home-manager/${username}/rofi.nix"
    ])
  ];

  home.packages = with pkgs; [
    desktopReloadScript
    swww # animated wallpaper for wayland window managers
    pywal # color theme changer
    dunst # notification daemon
    grim # screenshot tool
    wlr-randr # output management
  ];

  # labwc configuration files
  xdg.configFile = {
    "labwc/rc.xml".text = ''
      <?xml version="1.0"?>
      <labwc_config>
        <core>
          <decoration>server</decoration>
        </core>
        
        <theme>
          <name>Materia-light</name>
          <cornerRadius>5</cornerRadius>
        </theme>
        
        <keyboard>
          <numlock>yes</numlock>
          <repeatRate>35</repeatRate>
          <repeatDelay>200</repeatDelay>
          
          <keybind key="A-Return">
            <action name="Execute" command="alacritty" />
          </keybind>
          
          <keybind key="A-d">
            <action name="Execute" command="rofi -modes run,ssh -show run" />
          </keybind>
          
          <keybind key="A-s">
            <action name="Execute" command="ddcutil -d 1 setvcp D6 05 &amp;&amp; systemctl suspend" />
          </keybind>
          
          <keybind key="A-q">
            <action name="Close" />
          </keybind>
          
          <keybind key="A-f">
            <action name="ToggleFullscreen" />
          </keybind>
          
          <keybind key="A-t">
            <action name="ToggleDecorations" />
          </keybind>
          
          <!-- Focus movements -->
          <keybind key="A-h">
            <action name="Focus" direction="left" />
          </keybind>
          
          <keybind key="A-l">
            <action name="Focus" direction="right" />
          </keybind>
          
          <keybind key="A-k">
            <action name="Focus" direction="up" />
          </keybind>
          
          <keybind key="A-j">
            <action name="Focus" direction="down" />
          </keybind>
          
          <!-- Monitor input switching -->
          <keybind key="A-F1">
            <action name="Execute" command="ddcutil -d 1 setvcp 60 0x11" />
          </keybind>
          
          <keybind key="A-F2">
            <action name="Execute" command="ddcutil -d 1 setvcp 60 0x12" />
          </keybind>

          ${lib.optionalString (osConfig.networking.hostName == "alder") ''
          <keybind key="A-F8">
            <action name="Execute" command="rfkill toggle wlan" />
          </keybind>
          ''}

          <keybind key="A-F11">
            <action name="Execute" command="brightnessctl set 10%-" />
          </keybind>
          
          <keybind key="A-F12">
            <action name="Execute" command="brightnessctl set +10%" />
          </keybind>
          
          <!-- Window resizing -->
          <keybind key="A-S-Right">
            <action name="Resize" left="-100" />
          </keybind>
          <keybind key="A-S-Left">
            <action name="Resize" right="-100" />
          </keybind>
          <keybind key="A-S-Up">
            <action name="Resize" bottom="-100" />
          </keybind>
          <keybind key="A-S-Down">
            <action name="Resize" top="-100" />
          </keybind>
          
          <!-- Window moving -->
          <keybind key="A-S-h">
            <action name="MoveToEdge" direction="left" />
          </keybind>
          <keybind key="A-S-l">
            <action name="MoveToEdge" direction="right" />
          </keybind>
          <keybind key="A-S-k">
            <action name="MoveToEdge" direction="up" />
          </keybind>
          <keybind key="A-S-j">
            <action name="MoveToEdge" direction="down" />
          </keybind>
          
          <!-- Reload and quit -->
          <keybind key="A-S-r">
            <action name="Execute" command="desktopReload" />
          </keybind>
          
          <keybind key="A-S-q">
            <action name="Execute" command="${pkgs.wlogout}/bin/wlogout" />
          </keybind>
          
          <!-- Screenshot -->
          <keybind key="Print">
            <action name="Execute" command="grim -g &quot;$(slurp)&quot; - | wl-copy" />
          </keybind>
        </keyboard>
        
        <mouse>
          <default />
          <context name="Frame">
            <mousebind button="A-Left" action="Drag">
              <action name="Move" />
            </mousebind>
            <mousebind button="A-Right" action="Drag">
              <action name="Resize" />
            </mousebind>
          </context>
          <context name="Title">
            <mousebind button="Left" action="DoubleClick">
              <action name="ToggleMaximize" />
            </mousebind>
          </context>
          <context name="Root">
            <mousebind button="Right" action="Press">
              <action name="ShowMenu" menu="root-menu" />
            </mousebind>
          </context>
        </mouse>
        
        <desktops number="1" />
      </labwc_config>
    '';

    "labwc/menu.xml".text = ''
      <?xml version="1.0"?>
      <openbox_menu>
        <menu id="root-menu" label="labwc">
          <item label="Terminal">
            <action name="Execute" command="alacritty" />
          </item>
          <item label="Firefox">
            <action name="Execute" command="firefox" />
          </item>
          <item label="Calculator">
            <action name="Execute" command="gnome-calculator" />
          </item>
          <item label="File Manager">
            <action name="Execute" command="thunar" />
          </item>
          <separator />
          <item label="Reload Desktop">
            <action name="Execute" command="desktopReload" />
          </item>
          <separator />
          <item label="Reconfigure labwc">
            <action name="Reconfigure" />
          </item>
          <separator />
          <item label="Lock">
            <action name="Execute" command="swaylock" />
          </item>
          <item label="Exit">
            <action name="Execute" command="${pkgs.wlogout}/bin/wlogout" />
          </item>
        </menu>
      </openbox_menu>
    '';
    
    "labwc/autostart" = {
      text = ''
        #!/bin/sh
        
        # Start wallpaper daemon
        swww-daemon &
        
        # Start notification daemon
        dunst &
        
        # Wait a moment then reload desktop to set wallpaper and launch waybar
        sleep 2 && desktopReload &
      '';
      executable = true;
    };
    
    "labwc/environment".text = ''
      XDG_CURRENT_DESKTOP=labwc
      XDG_SESSION_TYPE=wayland
      MOZ_ENABLE_WAYLAND=1
      QT_QPA_PLATFORM=wayland
      QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    '';
  };
  
  # waybar configuration
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
        "wlr/workspaces"
      ];
      "modules-right" = [
        "tray"
      ] ++ lib.optionals (osConfig.networking.hostName == "alder") [
        "battery"
        "backlight"
      ] ++ [
        "temperature"
        "cpu"
        "memory"
        "disk"
        "bluetooth"
      ] ++ lib.optionals (osConfig.networking.hostName == "alder") [
        "network#wifi"
        "network#ethernet-dock"
      ] ++ [
        "network#ethernet"
        "network#tailscale"
        "clock"
      ];
      "wlr/workspaces" = {
        "format" = "{name}";
        "on-click" = "activate";
        "sort-by-number" = true;
      };
      "tray" = {
        "icon-size" = 18;
        "spacing" = 10;
      };
      "clock" = {
        "timezone" = "America/New_York";
        "format" = "{:%I:%M}";
      };
      "cpu" = {
        "format" = "{usage}% ";
      };
      "memory" = {
        "format" = "{percentage}% 󰘚";
      };
      "disk" = {
        "interval" = 10;
        "format" = "{percentage_used}% ";
        "path" = "/";
      };
      "temperature" = {
        "critical-threshold" = 80;
        "format-critical" = "{temperatureC}°C ";
        "format" = "{temperatureC}°C ";
      };
      "network#tailscale" = {
        "interface" = "tailscale0";
        "format" = "󰴳";
        "format-disconnected" = "󰦞";
        "format-linked" = "󰦞";
        "tooltip-format" = "Tailscale: {ipaddr}";
        "tooltip-format-disconnected" = "Tailscale: Disconnected";
      };
      "network#ethernet" = {
        "interface" = 
         if osConfig.networking.hostName == "cypress" then "enp1s0"
         else if osConfig.networking.hostName == "thinkpad" then "enp0s31f6"
         else "eth0";
        "format-ethernet" = "󰌗";
        "format-disconnected" = "󰌗";
        "tooltip-format-ethernet" = "Ethernet: {ipaddr}";
        "tooltip-format-disconnected" = "Ethernet: Disconnected";
      };
      "bluetooth" = {
        "format" = "";
        "format-connected" = " {num_connections}";
        "format-off" = "";
        "format-disabled" = "󰂲";
        "interval" = 5;
      };
      "network#wifi" = lib.mkIf (osConfig.networking.hostName == "alder") {
        "interface" = "wlan0";
        "format-wifi" = "{signalStrength}% ";
        "format-disconnected" = "󰖪";
        "tooltip-format-wifi" = "Wifi: {essid} {ipaddr}";
        "tooltip-format-disconnected" = "Wifi: Disconnected";
      };
      "network#ethernet-dock" = lib.mkIf (osConfig.networking.hostName == "thinkpad") {
        "interface" = "enp0s20f0u2u1u2";
        "format-ethernet" = "󰌗";
        "format-disconnected" = "󰌗";
        "tooltip-format-ethernet" = "Ethernet-Dock: {ipaddr}";
        "tooltip-format-disconnected" = "Ethernet-Dock: Disconnected";
      };
      "battery" = lib.mkIf (osConfig.networking.hostName == "thinkpad") {
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
      "backlight" = lib.mkIf (osConfig.networking.hostName == "alder") {
        "device" = "intel_backlight";
        "format" = "{percent}% {icon}";
        "format-icons" = ["󰛨"];
      };
    }];
    style = 
    ''
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