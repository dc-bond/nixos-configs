{ pkgs, ... }: 

{

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mainMod" = "Alt";
      bind = [
        "$mainMod, RETURN, exec, alacritty"
        "$mainMod, Q, killactive"
        ]
      
      extraConfig = ''
        
      '';
    };
  };

  home.packages = with pkgs; [
    waybar
    #(pkgs.waybar.overrideAttrs (oldAttrs: {
    #  mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    #})
    #)
    #eww-wayland # widgets
    swww # animated wallpaper for wayland window managers
    #swaylock-effects # wayland screenlock application
    #wlogout # wayland logout application
    #nwg-look # gtk settings manager for wayland
    rofi-wayland # application launcher
    pinentry-rofi # use rofi for pinentry
    rofi-calc # calculator add-on for rofi
    #wlr-randr # wayland display setting tool for external monitors
    pywal # color theme changer
    dunst # notification daemon
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
  
  #wayland.windowManager.hyprland.settings = {
  #  "$mod" = "SUPER";
  #  bind =
  #    [
  #      "$mod, F, exec, firefox"
  #      ", Print, exec, grimblast copy area"
  #    ]
  #    ++ (
  #      # workspaces
  #      # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
  #      builtins.concatLists (builtins.genList (
  #          x: let
  #            ws = let
  #              c = (x + 1) / 10;
  #            in
  #              builtins.toString (x + 1 - (c * 10));
  #          in [
  #            "$mod, ${ws}, workspace, ${toString (x + 1)}"
  #            "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
  #          ]
  #        )
  #        10)
  #    );
  #};

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