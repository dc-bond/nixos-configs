{ 
  pkgs,
  ... 
}: 

{

  environment = {
    systemPackages = with pkgs; [
      kdePackages.sddm-kcm # configuration module for sddm
      wayland-utils # wayland utilities
      wl-clipboard # command-line copy/paste utilities for wayland
    ];
    plasma6.excludePackages = with pkgs.kdePackages; [
      baloo-widgets
      elisa
      ffmpegthumbs
      kate # default kde text editor
      khelpcenter # kde help center
      kinfocenter # system info center
      kmenuedit # menu editor tool
      konsole # default kde terminal
      plasma-browser-integration
      plasma-systemmonitor # kde system monitor app
      xwaylandvideobridge
      ark # file archiver
      drkonqi # crashed process viewer
      spectacle # screenshot tool
      plasma-welcome # welcome screen
      discover # software center
    ];
    etc."xrdp/startwm.sh" = {
      text = ''
        #!/bin/sh
        
        unset SESSION_MANAGER
        unset DBUS_SESSION_BUS_ADDRESS
        
        if [ -r /etc/profile ]; then
          . /etc/profile
        fi
        
        export PLASMA_USE_QT_SCALING=1
        
        exec ${pkgs.dbus}/bin/dbus-run-session ${pkgs.kdePackages.plasma-workspace}/bin/startplasma-x11 --no-splash
      '';
      mode = "0755";
    };
  };

  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      enable = true;
      enableHidpi = true;
      wayland.enable = true;
      settings = {
        General = {
          Session = "plasmawayland";
          Theme = "breeze";
          #Background = "${repo-wallpaper}/wallpaper/your-background.png";
          Font = "Source Sans Pro";
          FontSize = "10";
          CursorTheme = "WhiteSur-cursors";
          CursorSize = "20";
        };
      };
    };
    xrdp = {
      enable = true;
      defaultWindowManager = "startplasma-x11";
      openFirewall = true; # opens port 3389
    };
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };
  };

  systemd.user.services = {
    "app-org.kde.discover.notifier@autostart".enable = false; # disable auto-update checker
    "app-org.kde.kalendarac@autostart".enable = false; # disable calendar launch
  };

}
