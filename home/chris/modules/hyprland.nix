{ lib, pkgs, ... }: 

{

  wayland.windowManager.hyprland = {
    enable = true;
    #xwayland.enable = false;
    extraConfig = ''

      # monitor setup
      #monitor=eDP-1, disable
      #monitor=eDP-1, 1920x1080@60, 0x0, 1
      #monitor=HDMI-A-2, 2560x1440@60, 0x0, 1
      #monitor=HDMI-A-2, disable

      # autostart
      #exec-once = ~/cypress-dotfiles/scripts/waybar-launch.sh
      exec-once = swww-daemon
      exec-once = swww img ~/nixos-configs/home/chris/wallpaper/wallpaper-1.jpg
      #exec-once = ~/nixos-configs/home/chris/scripts/pywal-swww.sh
      #exec-once = dunst
      #exec-once = ~/cypress-dotfiles/scripts/gtk.sh
      #exec-once = ~/cypress-dotfiles/scripts/autolock.sh &

      ## load pywal color file
      #source = ~/.cache/wal/colors-hyprland.conf

      ## environment variables
      #env = XCURSOR_SIZE,16
      #env = PATH,$PATH:$HOME/cypress-dotfiles/scripts:$HOME/.cargo/bin
      #env = EDITOR,nvim
      #env = VISUAL=nvim
      #env = TERM=xterm-256color

      # keyboard layout and mouse
      input {
          kb_layout = us
          kb_variant =
          kb_model =
          kb_options =
          kb_rules =
          follow_mouse = 1
          sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
          touchpad {
              natural_scroll = true
          }
      }

      # window layout and colors
      general {
          gaps_in = 0
          gaps_out = 0
          border_size = 1
          col.active_border = $color11
          col.inactive_border = rgba(ffffffff)
          layout = dwindle
      }

      # window decorations
      decoration {
          rounding = 5
          blur {
              enabled = true
              size = 6
              passes = 2
              new_optimizations = on
              ignore_opacity = true
              xray = true
              blurls = waybar
          }
          active_opacity = 1.0
          inactive_opacity = 0.8
          fullscreen_opacity = 1.0
      
          drop_shadow = true
          shadow_range = 30
          shadow_render_power = 3
          col.shadow = 0x66000000
      }

      # animations
      animations {
          enabled = true
          bezier = myBezier, 0.05, 0.9, 0.1, 1.05
          animation = windows, 1, 7, myBezier
          animation = windowsOut, 1, 7, default, popin 80%
          animation = border, 1, 10, default
          animation = borderangle, 1, 8, default
          animation = fade, 1, 7, default
          animation = workspaces, 1, 6, default
      }

      # layouts
      dwindle {
          pseudotile = true
          preserve_split = true
      }
      master {
          new_is_master = true
      }
      gestures {
          workspace_swipe = false
      }

      # window rules
      #windowrule = tile,^(Brave-browser)$
      #windowrule = tile,^(Chromium)$
      windowrule = float,^(pavucontrol)$
      windowrule = float,^(blueman-manager)$
      windowrule = float,^(iwdgui)$
      
      # keybindings
      $mainMod = Alt

      bind = $mainMod, RETURN, exec, rxvt-unicode
      bind = $mainMod, Q, killactive
      bind = $mainMod, F, fullscreen
      #bind = $mainMod, D, exec, rofi -show combi -combi-modes "drun,run,ssh" -modes combi
      #bind = $mainMod, C, exec, rofi -show calc -modi calc -no-show-match -no-sort
      bind = $mainMod, T, togglefloating
      bind = $mainMod, J, togglesplit
      bind = $mainMod, left, movefocus, l
      bind = $mainMod, right, movefocus, r
      bind = $mainMod, up, movefocus, u
      bind = $mainMod, down, movefocus, d
      
      bind = $mainMod, PRINT, exec, ~/cypress-dotfiles/scripts/screenshot.sh
      bind = $mainMod SHIFT, Q, exec, ~/cypress-dotfiles/scripts/powermenu.sh
      bind = $mainMod SHIFT, R, exec, ~/cypress-dotfiles/scripts/updatewal-swww.sh
      bind = $mainMod, F8, exec, rfkill toggle wlan
      #bind = $mainMod, F10, exec, rfkill toggle bluetooth
      bind = $mainMod, F5, exec, brightnessctl set 10%-
      bind = $mainMod, F6, exec, brightnessctl set +10%
      
      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5
      bind = $mainMod, 6, workspace, 6
      bind = $mainMod, 7, workspace, 7
      bind = $mainMod, 8, workspace, 8
      bind = $mainMod, 9, workspace, 9
      bind = $mainMod, 0, workspace, 10
      
      bind = $mainMod SHIFT, 1, movetoworkspace, 1
      bind = $mainMod SHIFT, 2, movetoworkspace, 2
      bind = $mainMod SHIFT, 3, movetoworkspace, 3
      bind = $mainMod SHIFT, 4, movetoworkspace, 4
      bind = $mainMod SHIFT, 5, movetoworkspace, 5
      bind = $mainMod SHIFT, 6, movetoworkspace, 6
      bind = $mainMod SHIFT, 7, movetoworkspace, 7
      bind = $mainMod SHIFT, 8, movetoworkspace, 8
      bind = $mainMod SHIFT, 9, movetoworkspace, 9
      bind = $mainMod SHIFT, 0, movetoworkspace, 10
      
      bind = $mainMod, mouse_down, workspace, e+1
      bind = $mainMod, mouse_up, workspace, e-1
      
      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow
      
      bind = $mainMod SHIFT, right, resizeactive, 100 0
      bind = $mainMod SHIFT, left, resizeactive, -100 0
      bind = $mainMod SHIFT, up, resizeactive, 0 -100
      bind = $mainMod SHIFT, down, resizeactive, 0 100
      
      # misc settings
      misc {
          disable_hyprland_logo = true
          disable_splash_rendering = true
      }
      
      input {
          repeat_delay = 200
          repeat_rate = 40
      }
      
      device {
          name = razer-proclickm-1
          sensitivity = -0.7 
      }

    '';
  };

  home.packages = with pkgs; [
    #waybar
    #(pkgs.waybar.overrideAttrs (oldAttrs: {
    #  mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    #})
    #)
    #eww-wayland # widgets
    swww # animated wallpaper for wayland window managers
    #swaylock-effects # wayland screenlock application
    #wlogout # wayland logout application
    #nwg-look # gtk settings manager for wayland
    #rofi-wayland # application launcher
    #pinentry-rofi # use rofi for pinentry
    #rofi-calc # calculator add-on for rofi
    #rofi-pass-wayland # add pass functionality to rofi
    #wlr-randr # wayland display setting tool for external monitors
    pywal # color theme changer
    dunst # notification daemon
    #polkit-kde-agent # kde gui authentication agent
    #libnotify # library to support notification daemons
    #xfce.xfce4-power-manager # laptop power manager
    ##xdg-desktop-portal-hyprland # allow applications to communicate with window manager
    #grim # wayland screenshot tool
    #slurp # wayland region selector
    #scrot # screenshot tool
    #xfce.thunar # file manager
    ##filelight # disk usage visualizer
    #firefox # web browser
    #mupdf # pdf viewer
    #nextcloud-client # client for connecting to nextcloud servers
    ##ffmpegthumbnailer
    ##nvidia
    #autorandr # automatically select a display configuration based on connected devices
    #ddcutil # query and change monitor settings using DDC/CI and USB
    #brightnessctl # screen brightness application
    ##xorg-xset # tool to set keyboard repeat delay
    #bleachbit # disk cleaner
  ];

# alacritty terminal
  programs.alacritty = {
    enable = true;
    #settings = {
    #  font = {
    #    normal = {
    #      family = "SauceCodePro NF";
    #      style = "Regular";
    #    };
    #    bold = {
    #      family = "SauceCodePro NF";
    #      style = "Bold";
    #    };
    #    italic = {
    #      family = "SauceCodePro NF";
    #      style = "Italic";
    #    };
    #    bold_italic = {
    #      family = "SauceCodePro NF";
    #      style = "Bold Italic";
    #    };
    #    size = 11.0;
    #  };
    #};
  };

# waybar
  programs.waybar = {
    enable = true;
    settings = { 
      lib.importJSON = ../waybar/config.json;
    };
    style = ''
    
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
      
      #custom-updates {
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
      
      #clock {
          font-size: 14px;
          color: #ffffff;
          padding: 1px 10px 1px 10px;
      }
      
      #pulseaudio {
          color: #ffffff;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      
      #pulseaudio.muted {
          color: #ffffff;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      
      #network.vpn {
          color: #00ff00;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      
      #network.ethernet {
          color: #00ff00;
          font-size: 14px;
          padding: 1px 10px 1px 10px;
      }
      
      #network.wifi {
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

# rofi
  programs.rofi = {
    enable = true;
    #package = "rofi-wayland";
  };

}