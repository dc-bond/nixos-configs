{ 
  config, 
  pkgs, 
  ... 
}: 

{

  home.packages = with pkgs; [
    (import ../../scripts/common/desktopReload.nix { inherit pkgs config; })
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = 
    ''
      device {
        name=razer-proclickm
        sensitivity=-0.6
      }
      device {
        name=razer-proclickm-1
        sensitivity=-0.6
      }
    '';
    settings = {
      "$mod" = "Alt";
      exec-once = [
        "desktopReload" # nix script to load wallpaper, launch waybar, etc.
        "swww-daemon"
        "dunst"
        "[workspace 1 silent] firefox"
        "[workspace 2 silent] alacritty"
        "[workspace 3 silent] ${pkgs.vscodium}/bin/codium"
        "sleep 5 && nextcloud"
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
        "$mod, F3, exec, ddcutil -d 1 setvcp 60 0x0f" # switch monitor input to DP1(opticon)
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
        "$mod SHIFT, R, exec, desktopReload"
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
      #source = [
      #  "~/.cache/wal/colors-hyprland.conf" # not working
      #];
      windowrulev2 = [
        #"bordercolor rgb(FF0000) rgb(880808), fullscreen:1" # set bordercolor to red if window is fullscreen
        "size 1154 706, class:(com.saivert.pwvucontrol)"
        "size 451 607, class:(org.gnome.Calculator)"
      ];
      windowrule = [
        "float, ^(com.saivert.pwvucontrol)$"
        "float, ^(org.gnome.Calculator)$"
        "float, ^(com.nextcloud.desktopclient.nextcloud)$"
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
      #device = {
      #  name = "razer-proclickm";
      #  sensitivity = "-0.5";
      #};
      #device = {
      #  name = "razer-proclickm-1";
      #  sensitivity = "-0.5";
      #};
      general = {
        gaps_in = 0;
        gaps_out = 0;
        border_size = 1;
        #col.active_border = "0xffffffff"; # broken?
        #col.inactive_border = "0xff444444"; # broken?
        layout = "dwindle"; # see settings below
      };
      #master = {
      #  orientation = "left";
      #  allow_small_split = true;
      #  new_on_top = false;
      #};
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
        drop_shadow = true;
        shadow_range = "30";
        shadow_render_power = "3";
        #col.shadow = "0x66000000";
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
          path = "/home/chris/nixos-configs/home-manager/wallpaper/wallpaper-1.jpg";
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
          #font_color = "##cdd6f4";
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