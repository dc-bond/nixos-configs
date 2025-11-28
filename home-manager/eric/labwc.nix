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
    gnome-calculator # calculator
    loupe # image viewer
    zathura # barebones pdf viewer
    #libreoffice-still # office suite
    #element-desktop # matrix chat app
    #nextcloud-client # nextcloud local syncronization client
    hyprshot # screenshot tool
    pwvucontrol # pipewire audio volume control app
  ];

  gtk = {
    enable = true;
    theme = {
      name = "Materia-light";
      package = pkgs.materia-theme;
    };
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-nord;
    };
    font = {
      name = "Source Sans Pro";
      package = null; # already installed in fonts.nix system-level module
      size = 10;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = false;  # since using materia light
    };
  };

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
          
          <keybind key="A-q">
            <action name="Close" />
          </keybind>
          
          <keybind key="A-f">
            <action name="ToggleFullscreen" />
          </keybind>
          
          <keybind key="A-t">
            <action name="ToggleDecorations" />
          </keybind>
          
          <keybind key="A-F8">
            <action name="Execute" command="rfkill toggle wlan" />
          </keybind>

          <keybind key="A-F11">
            <action name="Execute" command="brightnessctl set 10%-" />
          </keybind>
          
          <keybind key="A-F12">
            <action name="Execute" command="brightnessctl set +10%" />
          </keybind>
          
          <keybind key="A-S-q">
            <action name="Execute" command="${pkgs.wlogout}/bin/wlogout" />
          </keybind>
          
          <keybind key="Print">
            <action name="Execute" command="hyprshot -m region output --clipboard-only" />
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
            <action name="Execute" command="firefox-esr" />
          </item>
          <item label="Calculator">
            <action name="Execute" command="gnome-calculator" />
          </item>
          <item label="File Manager">
            <action name="Execute" command="thunar" />
          </item>
          <separator />
          <item label="Reload Wallpaper">
            <action name="Execute" command="desktopReload" />
          </item>
          <separator />
          <item label="Lock Screen">
            <action name="Execute" command="hyprlock" />
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
        swww-daemon &
        dunst &
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
        "wlr/taskbar"
      ];
      "modules-right" = [
        "tray"
        "backlight"
        "bluetooth"
        "network#wifi"
        "network#tailscale"
        "clock"
      ];
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
        "icon-size" = 18;
        "spacing" = 10;
      };
      "clock" = {
        "timezone" = "America/New_York";
        "format" = "{:%I:%M}";
        "tooltip-format" = "{:%A, %B %d, %Y}";
      };
      "network#tailscale" = {
        "interface" = "tailscale0";
        "format" = "󰴳";
        "format-disconnected" = "󰦞";
        "format-linked" = "󰦞";
        "tooltip-format" = "Tailscale: {ipaddr}";
        "tooltip-format-disconnected" = "Tailscale: Disconnected";
      };
      "bluetooth" = {
	      "format" = "";
        "format-connected" = "{num_connections}";
	      "format-off" = "";
        "format-disabled" = "󰂲";
        "tooltip-format" = "Bluetooth: {status}";
        "tooltip-format-connected" = "Bluetooth: {device_enumerate}";
        "tooltip-format-enumerate-connected" = "{device_alias}";
        "interval" = 5;
      };
      "network#wifi" = {
        "interface" = "wlan0";
        "format-wifi" = "{signalStrength}% ";
        "format-disconnected" = "󰖪";
        "tooltip-format-wifi" = "Wifi: {essid} {ipaddr}";
        "tooltip-format-disconnected" = "Wifi: Disconnected";
      };
      "backlight" = {
        "device" = "intel_backlight";
        "format" = "{percent}% {icon}";
        "format-icons" = ["󰛨"];
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
      
      #taskbar button {
        padding: 0 5px;
        margin: 0 2px;
        border-radius: 5px;
        color: #ffffff;
        background-color: transparent;
        opacity: 0.8;
      }
      
      #taskbar button.active {
        background-color: @color11;
        opacity: 1.0;
      }
      
      #taskbar button.minimized {
        opacity: 0.5;
      }
      
      #taskbar button:hover {
        background-color: @color1;
        opacity: 1.0;
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
      
      #network.disconnected,
      #network.disabled,
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
      
      #bluetooth.off,
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

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        grace = 0;
        hide_cursor = true;
        no_fade_in = false;
        no_fade_out = false;
      };
      background = [
        {
          path = "${wallpaperDir}/wallpaper-92.jpg";
          blur_passes = 3;
          contrast = 1;
          brightness = 0.5;
          vibrancy = 0.2;
          vibrancy_darkness = 0.2;
        }
      ];
      input-field = [
        {
          monitor = "";
          size = "350, 60";
          outline_thickness = 2;
          dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
          dots_spacing = 0.35; # Scale of dots' absolute size, 0.0 - 1.0
          dots_center = true;
          outer_color = "rgba(0, 0, 0, 0)";
          inner_color = "rgba(0, 255, 34, 0.2)";
          fade_on_empty = false;
          rounding = -1;
          check_color = "rgb(204, 136, 34)";
          placeholder_text = "<b><span foreground='##cdd6f4'>AUTHENTICATION REQUIRED</span></b>";
          hide_input = false;
          position = "0, -200";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
  
}