{ config, pkgs, ... }: 

{

# module imports
  imports = [
    ./alacritty.nix
    ./rofi.nix
    ./waybar.nix
  ];

  #home.file."${config.xdg.configHome}/hypr" = {
  #  source = ../dotfiles/hypr;
  #  recursive = true;
  #};

  home.packages = with pkgs; [
    #eww-wayland # widgets
    swww # animated wallpaper for wayland window managers
    #swaylock-effects # wayland screenlock application
    #wlogout # wayland logout application
    #nwg-look # gtk settings manager for wayland
    pywal # color theme changer
    dunst # notification daemon
    #polkit-kde-agent # kde gui authentication agent
    #libnotify # library to support notification daemons
    #xfce.xfce4-power-manager # laptop power manager
    ##xdg-desktop-portal-hyprland # allow applications to communicate with window manager
    #grim # wayland screenshot tool
    #slurp # wayland region selector
    #scrot # screenshot tool
    xfce.thunar # file manager
    ##filelight # disk usage visualizer
    #mupdf # pdf viewer
    #nextcloud-client # client for connecting to nextcloud servers
    ##ffmpegthumbnailer
    ##nvidia
    #wlr-randr # wayland display setting tool for external monitors
    #autorandr # automatically select a display configuration based on connected devices
    #ddcutil # query and change monitor settings using DDC/CI and USB
    brightnessctl # screen brightness application
    ##xorg-xset # tool to set keyboard repeat delay
    #bleachbit # disk cleaner
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "Alt";
      bind = [
        "$mod, RETURN, exec, alacritty"
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
      #bindl = [
      #  ", switch:on:Lid Switch,exec,hyprctl keyword monitor "eDP-1, disable""
      #  ", switch:off:Lid Switch,exec,hyprctl keyword monitor "eDP-1, 1920x1080@60, 1920, 1""
      #];
      #monitor = [
      #  "eDP-1, 1920x1080@60, 1920x0, 1"
      #  "DP-6, 2560x1440@144, 0x0, 1"
      #];
    };
    extraConfig = ''
      monitor = eDP-1, 1920x1080@60, 1920x0, 1
      monitor = DP-6, 2560x1440@144, 0x0, 1
      exec-once = swww-daemon
      exec-once = ~/nixos-configs/home/chris/dotfiles/hypr/pywal-swww.sh
      exec-once = dunst
      bindl = , switch:on:Lid Switch,exec,hyprctl keyword monitor "eDP-1, disable"
      bindl = , switch:off:Lid Switch,exec,hyprctl keyword monitor "eDP-1, 1920x1080@60, 1920, 1"
    '';
  };














## themes
#  home.pointerCursor = {
#    gtk.enable = true;
#    # x11.enable = true;
#    package = pkgs.bibata-cursors;
#    name = "Bibata-Modern-Classic";
#    size = 16;
#  };
#  
#  gtk = {
#    enable = true;
#    theme = {
#      package = pkgs.flat-remix-gtk;
#      name = "Flat-Remix-GTK-Grey-Darkest";
#    };
#  
#    iconTheme = {
#      package = pkgs.gnome.adwaita-icon-theme;
#      name = "Adwaita";
#    };
#  
#    font = {
#      name = "Sans";
#      size = 11;
#    };
#  };

}