{ 
  config,
  lib,
  configLib,
  pkgs, 
  ... 
}: 

{

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "home-manager/chris/common/alacritty.nix"
      "home-manager/chris/common/gammastep.nix"
      "home-manager/chris/common/vscodium.nix"
      "home-manager/chris/common/firefox.nix"
      "home-manager/chris/common/theme.nix"
      "home-manager/chris/common/rofi.nix"
    ])
  ];

  home.packages = with pkgs; [
    (import (configLib.relativeToRoot "scripts/desktop-reload.nix") { inherit pkgs config; })
    swww # animated wallpaper for wayland window managers
    pywal # color theme changer
    dunst # notification daemon
    gnome-calculator # calculator
    loupe # image viewer
    feh # image viewer
    zathura # barebones pdf viewer
    libreoffice-still # office suite
    element-desktop # matrix chat app
    nextcloud-client # nextcloud local syncronization client
    wayland-utils # wayland utilities
    wl-clipboard # wayland system clipboard
    hyprshot # screenshot tool
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "Alt";
      exec-once = [
        "swww-daemon"
        "dunst"
        "[workspace 2 silent] alacritty"
        "sleep 2 & desktop-reload" # nix script to load wallpaper, launch waybar, etc.
        "sleep 3 && nextcloud"
      ];      
      bind = [
        "$mod, RETURN, exec, alacritty"
	      "$mod, D, exec, rofi -modes run,ssh -show run"
        "$mod, S, exec, ddcutil -d 1 setvcp D6 05 && systemctl suspend"
        "$mod, Q, killactive"
        "$mod, F, fullscreen"
        "$mod, T, togglefloating"
        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"
        "$mod, F1, exec, ddcutil -d 1 setvcp 60 0x11" # switch monitor input to HDMI1 (work computer)
        "$mod, F2, exec, ddcutil -d 1 setvcp 60 0x12" # switch monitor input to HDMI2 (thinkpad)
        "$mod, F3, exec, ddcutil -d 1 setvcp 60 0x0f" # switch monitor input to DP1 (aspen)
        "$mod, F8, exec, rfkill toggle wlan"
        "$mod, F10, exec, rfkill toggle bluetooth"
        "$mod, F5, exec, brightnessctl set 10%-"
        "$mod, F6, exec, brightnessctl set +10%"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
        "$mod SHIFT, R, exec, desktop-reload"
        "$mod SHIFT, Q, exec, ${pkgs.wlogout}/bin/wlogout"
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"
        "$mod SHIFT, right, resizeactive, 100 0"
        "$mod SHIFT, left, resizeactive, -100 0"
        "$mod SHIFT, up, resizeactive, 0 -100"
        "$mod SHIFT, down, resizeactive, 0 100"
        "$mod SHIFT, h, movewindow, l"
        "$mod SHIFT, l, movewindow, r"
        "$mod SHIFT, k, movewindow, u"
        "$mod SHIFT, j, movewindow, d"
        " , PRINT, exec, hyprshot -m region output --clipboard-only" # screenshot a mouse region selection to clipboard
      ];
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
      bindl = [
        ", switch:on:Lid Switch,exec,hyprctl keyword monitor desc:Chimei Innolux Corporation 0x14D4, disable" # when laptop lid is closed, disable laptop screen
        ", switch:off:Lid Switch,exec,hyprctl keyword monitor desc:Chimei Innolux Corporation 0x14D4, 1920x1080@60, auto-right, 1" # when laptop lid is open, enable laptop screen and put it to the right of 32" external monitor
      ];
      monitor = [
        "desc:ASUSTek COMPUTER INC ASUS VG32V 0x0001618C, 2560x1440@100, 0x0, 1" # main 32" monitor
        "desc:Chimei Innolux Corporation 0x14D4, 1920x1080@60, auto-right, 1" # laptop screen
      ];
      env = [
        "SSH_AUTH_SOCK,/run/user/1000/gnupg/S.gpg-agent.ssh" # workaround to ensure ssh_auth_sock variable inherited by all applications instead of just interactive shell when using gpg-agent to serve ssh
      ];
      windowrulev2 = [
        "size 1154 706, class:(com.saivert.pwvucontrol)"
        "size 451 607, class:(org.gnome.Calculator)"
      ];
      windowrule = [
        "float, class:^(com.saivert.pwvucontrol)$"
        "float, class:^(org.gnome.Calculator)$"
        "float, class:^(com.nextcloud.desktopclient.nextcloud)$"
      ];
      input = {
        kb_layout = "us";
        numlock_by_default = true;
        repeat_delay = "200";
        repeat_rate = "35";
        follow_mouse = "1";
        accel_profile = "adaptive";
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
        };
      };
      general = {
        gaps_in = 0;
        gaps_out = 0;
        border_size = 1;
        layout = "dwindle"; # see settings below
      };
      dwindle = {
        force_split = 2;
        pseudotile = true;
        preserve_split = true;
      };
      decoration = {
        rounding = "5";
        active_opacity = "0.9";
        inactive_opacity = "0.7";
        fullscreen_opacity = "0.9";
        blur = {
          enabled = true;
          size = "6";
          passes = "2";
          new_optimizations = "on";
          ignore_opacity = true;
          xray = true;
          blurls = "waybar";
        };
      };
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [ 
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };
      gestures = {
        workspace_swipe = false;
      };
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };
      debug = {
        disable_logs = false;
      };
    };
  };

  programs = {

    zsh = {
      initContent = ''

        reconnect-mouse() {
          echo "restarting bluetooth service..."
          sudo systemctl restart bluetooth
          sleep 3
          
          echo "power cycling bluetooth..."
          bluetoothctl power off
          sleep 2
          bluetoothctl power on
          sleep 3
          
          echo "reconnecting mouse..."
          bluetoothctl connect D3:CF:05:5D:88:79
          echo "Bluetooth reconnection complete!"
        }

        librewolf-private() {
          echo "launching LibreWolf..."
          librewolf --private-window "https://ipleak.net" "$@"
        }

      '';
    };

    waybar = {
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
          "tray"
	        "temperature"
	        "backlight" # not working
	        "cpu"
	        "memory"
	        "disk"
          "battery"
          "bluetooth"
          "network#tailscale"
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
        "tray" = {
          "icon_size" = 18;
	        "spacing" = 10;
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
        "network#tailscale" = {
          "interface" = "tailscale0";
          "format" = "󰴳";
          "format-disconnected" = "󰦞";
          "format-linked" = "󰦞"; # this is a bug
          "tooltip-format" = "Tailscale: {ipaddr}";
          "tooltip-format-disconnected" = "Tailscale: Disconnected"; # not working bug
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
        #tray {
            color: #ffffff;
            font-size: 14px;
            padding: 1px 10px 1px 10px;
        }
      ''; 
    };
    
    hyprlock = {
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
            path = "/home/chris/nixos-configs/wallpaper/wallpaper-1.jpg";
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
            inner_color = "rgba(0, 0, 0, 0.2)";
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

  };

}