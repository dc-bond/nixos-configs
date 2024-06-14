{ config, pkgs, ... }: 

{

# module imports
  imports = [
    #./theme.nix
    ./alacritty.nix
    ./rofi.nix
    ./waybar.nix
    ./gammastep.nix
    ./nextcloud-client.nix
    ./vscodium.nix
    ./firefox.nix
  ];

  home.packages = with pkgs; [
    #eww-wayland # widgets
    swww # animated wallpaper for wayland window managers\
    #swaylock-effects # wayland screenlock application
    #wlogout # wayland logout application
    #nwg-look # gtk settings manager for wayland
    pywal # color theme changer
    dunst # notification daemon
    #polkit-kde-agent # kde gui authentication agent
    #libnotify # library to support notification daemons
    #xfce.xfce4-power-manager # laptop power manager
    #grim # wayland screenshot tool
    #slurp # wayland region selector
    #scrot # screenshot tool
    xfce.thunar # file manager
    filelight # disk usage visualizer
    #mupdf # pdf viewer
    ##ffmpegthumbnailer
    #wlr-randr # wayland display setting tool for external monitors
    #autorandr # automatically select a display configuration based on connected devices
    #ddcutil # query and change monitor settings using DDC/CI and USB
    #bleachbit # disk cleaner
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      device {
        name=razer-proclickm
        sensitivity=-0.5
      }
      device {
        name=razer-proclickm-1
        sensitivity=-0.5
      }
    '';
    settings = {
      "$mod" = "Alt";
      exec-once = [
        "swww-daemon"
        "~/nixos-configs/home/chris/dotfiles/hypr/pywal-swww.sh"
        "dunst"
      ];      
      bind = [
        "$mod, RETURN, exec, alacritty"
	      "$mod, D, exec, rofi -show combi -combi-modes drun,run,ssh -modes combi"
	      "$mod, C, exec, rofi -show calc -modi calc -no-show-match -no-sort" # not working
        "$mod, E, exec, thunar"
        "$mod, Q, killactive"
        "$mod, F, fullscreen"
        "$mod, T, togglefloating"
        "$mod, J, togglesplit"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
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
        "$mod SHIFT, R, exec, ~/nixos-configs/home/chris/dotfiles/hypr/pywal-swww.sh"
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
        ", switch:on:Lid Switch,exec,hyprctl keyword monitor eDP-1, disable"
        ", switch:off:Lid Switch,exec,hyprctl keyword monitor eDP-1, 1920x1080@60, 1920, 1"
      ];
      monitor = [
        "eDP-1, 1920x1080@60, 1920x0, 1"
        "DP-6, 2560x1440@144, 0x0, 1"
      ];
      environment = [
        "XCURSOR_SIZE,16"
        "EDITOR,nvim"
        "VISUAL=nvim"
        "TERM=xterm-256color"
      ];
      #source = [
      #  "~/.cache/wal/colors-hyprland.conf" # not working
      #];
      windowrule = [
        "float,^(pavucontrol)$"
        "float,^(blueman-manager)$" # not working
      ];
      input = {
        kb_layout = "us";
        numlock_by_default = true;
        repeat_delay = "200";
        repeat_rate = "35";
        follow_mouse = "1";
        accel_profile = "adaptive";
        #accel_profile = "custom 200 0.0 0.5";
        #sensitivity = "0";
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
        pseudotile = true;
        preserve_split = true;
      };
      master = {
        new_is_master = true;
      };
      gestures = {
        workspace_swipe = false;
      };
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };
    };
  };

}
