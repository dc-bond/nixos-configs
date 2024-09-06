{ 
  config, 
  pkgs, 
  ... 
}: 

{

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
        "swww-daemon"
        "dunst"
        "sleep 1 && firefox"
        "sleep 2 && alacritty"
        "sleep 3 && codium"
        "sleep 4 && nextcloud"
        "desktopReload" # nix script
        #"wl-paste --type text --watch cliphist store"
      ];      
      bind = [
        "$mod, RETURN, exec, alacritty"
	      "$mod, D, exec, rofi -show combi -combi-modes drun,run,ssh -modes combi"
	      "$mod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
        "$mod, S, exec, ddcutil -d 1 setvcp D6 05 && systemctl suspend"
        "$mod, Q, killactive"
        "$mod, F, fullscreen"
        "$mod, T, togglefloating"
        "$mod, J, togglesplit"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
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
      ];
      windowrule = [
        "workspace 1 silent, firefox"
        "workspace 2 silent, alacritty"
        #"workspace 3 silent, codium"
        #"workspace 10 silent, nextcloud"
        #"float, ^(blueman-manager)$" # not working
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
        #col.active_border = "$color11";
        #col.inactive_border = "rgba(ffffffff)";
        layout = "dwindle";
      };
      decoration = {
        rounding = "5";
        active_opacity = "1.0";
        inactive_opacity = "0.8";
        fullscreen_opacity = "1.0";
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
      dwindle = {
        force_split = 2;
        #pseudotile = true;
        #preserve_split = true;
      };
      master = {
        orientation = "left";
        allow_small_split = true;
        new_on_top = true;
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

}