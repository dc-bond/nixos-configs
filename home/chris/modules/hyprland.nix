{ config, pkgs, ... }: 

{

# module imports
  imports = [
    ./alacritty.nix
    ./rofi.nix
    ./waybar.nix
  ];

  home.file."${config.xdg.configHome}/hypr" = {
    source = ../dotfiles/hypr;
    recursive = true;
  };

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