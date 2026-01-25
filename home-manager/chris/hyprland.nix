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
    ${pkgs.pywal}/bin/wal -s -t -q -i ${wallpaperDir}
    
    # load current pywal color scheme
    source "$HOME/.cache/wal/colors.sh"
    
    # copy color file to waybar folder
    ${pkgs.coreutils}/bin/cp ~/.cache/wal/colors-waybar.css ~/.config/waybar/
    ${pkgs.coreutils}/bin/cp $wallpaper ~/.cache/current_wallpaper.jpg
    
    # get wallpaper image name
    newwall=$(${pkgs.coreutils}/bin/echo $wallpaper | ${pkgs.gnused}/bin/sed "s|~/nixos-configs/wallpaper/||g")
    
    # set the new wallpaper
    ${pkgs.swww}/bin/swww img $wallpaper --transition-step 20 --transition-fps=20
    
    # reload waybar (restart if running, start if not)
    ${pkgs.systemd}/bin/systemctl --user restart waybar.service 2>/dev/null || ${pkgs.systemd}/bin/systemctl --user start waybar.service
    
    # send notification
    #${pkgs.dunst}/bin/dunstify "Wallpaper and Taskbar Reloaded"
  '';
in

{

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "home-manager/shared/alacritty.nix"
      "home-manager/shared/rofi.nix"
      "home-manager/shared/waybar.nix"
      "home-manager/shared/hyprlock.nix"
      "home-manager/shared/gammastep.nix"
      "home-manager/${username}/firefox.nix"
      "home-manager/${username}/vscodium.nix"
    ])
  ];

  home = {
    packages = with pkgs; [
      desktopReloadScript
      swww # animated wallpaper for wayland window managers
      pywal # color theme changer
      dunst # notification daemon
      gnome-calculator # calculator
      loupe # image viewer
      zathura # barebones pdf viewer
      libreoffice-still # office suite
      element-desktop # matrix chat app
      nextcloud-client # nextcloud local syncronization client
      hyprshot # screenshot tool
      pwvucontrol # pipewire audio volume control app
      claude-code # terminal-based agentic coding assistant
      tigervnc # vnc client app
    ];
    pointerCursor = {
      enable = true;
      name = "WhiteSur-cursors";
      package = pkgs.whitesur-cursors;
      size = 20;
      gtk.enable = true; # integrate with gtk apps
    };
  };

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

  # override element desktop entry to specify keyring backend
  xdg.desktopEntries.element-desktop = {
    name = "Element";
    exec = "element-desktop --password-store=gnome-libsecret %u";
    icon = "element";
    type = "Application";
    categories = [ "Network" "InstantMessaging" "Chat" ];
    mimeType = [ "x-scheme-handler/element" ];
  };

  #1. Hyprland starts → triggers graphical-session.target
  #2. Waybar starts via systemd (may initially fail to load colors properly since desktopReload has not run yet)
  #3. desktopReload service starts automatically after waybar
  #4. 2-second delay ensures everything is settled
  #5. desktopReload runs → creates colors and restarts waybar
  #6. Waybar reloads with proper colors
  systemd.user = {
    services.desktopReload = {
      Unit = {
        Description = "Reload desktop theme and wallpaper";
        After = [ "graphical-session.target" "waybar.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        ExecStart = "${desktopReloadScript}/bin/desktopReload";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
    timers.desktopReload = {
      Unit = {
        Description = "Desktop reload timer";
      };
      Timer = {
        OnCalendar = "hourly";
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "Alt";
      exec-once = [
        "swww-daemon"
        "dunst"
        "firefox-esr"
        "alacritty"
        "codium"
        "element-desktop"
        "sleep 1 && nextcloud"
      ];
      bind = [
        "$mod, RETURN, exec, alacritty"
	      "$mod, d, exec, rofi -show drun"
        "$mod, c, exec, rofi -show calc -modi calc -no-show-match -no-sort"
        "$mod, b, exec, rofi-bluetooth"
        "$mod, s, exec, ddcutil -d 1 setvcp D6 05 && systemctl suspend"
        "$mod, q, killactive"
        "$mod, f, fullscreen"
        "$mod, t, togglefloating"
        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"
        "$mod, F1, exec, ddcutil -d 1 setvcp 60 0x11" # switch monitor input to HDMI1
        "$mod, F2, exec, ddcutil -d 1 setvcp 60 0x12" # switch monitor input to HDMI2
        #"$mod, F3, exec, ddcutil -d 1 setvcp 60 0x0f" # switch monitor input to DP1
        ] ++ lib.optional (osConfig.networking.hostName == "thinkpad") "$mod, F8, exec, rfkill toggle wlan" ++ [
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
        "$mod SHIFT, Q, exec, rofiPowerMenu"
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
      bindl = lib.optionals (osConfig.networking.hostName == "thinkpad") [
        ", switch:on:Lid Switch,exec,hyprctl keyword monitor desc:Chimei Innolux Corporation 0x14D4, disable"
        ", switch:off:Lid Switch,exec,hyprctl keyword monitor desc:Chimei Innolux Corporation 0x14D4, 1920x1080@60, auto-right, 1"
      ];
      monitor = [
        "desc:ASUSTek COMPUTER INC ASUS VG32V 0x0001618C, 2560x1440@144, 0x0, 1"
      ] ++ lib.optional (osConfig.networking.hostName == "thinkpad") "desc:Chimei Innolux Corporation 0x14D4, 1920x1080@60, auto-right, 1";
      env = [
        "SSH_AUTH_SOCK,/run/user/1000/gnupg/S.gpg-agent.ssh" # workaround to ensure ssh_auth_sock variable inherited by all applications instead of just interactive shell when using gpg-agent to serve ssh
      ];
      windowrulev2 = [
        "size 1154 706, class:(com.saivert.pwvucontrol)"
        "size 451 607, class:(org.gnome.Calculator)"
        "workspace 1 silent, class:^(firefox-esr)$"
        "workspace 2 silent, class:^(Alacritty)$"
        "workspace 3 silent, class:^(VSCodium)$"
        "workspace 10 silent, class:^(Element)$"
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
