{ inputs, pkgs, ... }: 

{

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    #nvidiaPatches = true;
    #xwayland.enable = false;
    #settings = {

    #};
    extraConfig = ''
      exec-once = swww-daemon
      exec-once = swww img ~/nixos-configs/home/chris/wallpaper/wallpaper-1.jpg
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

## allow applications to communicate with compositor
#  xdg.portal = {
#    enable = true;
#    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
#  };

## environment
#  environment.sessionVariables = {
#    NIXOS_OZONE_WL = "1";
#    #WLR_NO_HARDWARE_CURSORS = "1"; # if cursor does not appear
#  };

# alacritty terminal
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = {
          family = "SauceCodePro NF";
          style = "Regular";
        };
        bold = {
          family = "SauceCodePro NF";
          style = "Bold";
        };
        italic = {
          family = "SauceCodePro NF";
          style = "Italic";
        };
        bold_italic = {
          family = "SauceCodePro NF";
          style = "Bold Italic";
        };
        size = 11.0;
      };
    };
  };

}