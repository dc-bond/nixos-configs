{ 
  pkgs,
  config,
  ... 
}: 

{

  #sops = {
  #  secrets.krfbPasswd = {};
  #  templates = {
  #    "krfbPasswd" = {
  #      content = config.sops.placeholder.krfbPasswd;
  #      owner = "chris";
  #      mode = "0400";
  #    };
  #  };
  #};

  environment = {
    systemPackages = with pkgs; [
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
  };

  services = {
    desktopManager.plasma6.enable = true;
    displayManager.ly = {
      enable = true;
      settings = {
        lang = en;
        numlock = true;
        animation = "out";
        max_login_tries = 3;
        save_session = true;
        session = "plasmawayland";
      };
    };
    #displayManager.sddm = {
    #  enable = true;
    #  enableHidpi = true;
    #  wayland.enable = true;
    #  settings = {
    #    General = {
    #      Numlock = "on";
    #    };
    #    Theme = {
    #      #Background = "${repo-wallpaper}/wallpaper/your-background.png";
    #      Font = "Source Sans Pro";
    #      CursorTheme = "WhiteSur-cursors";
    #      CursorSize = "20";
    #      EnableAvatars = "true"; # search ~/.face.icon for avatar picture
    #    };
    #  };
    #};
  };

  #networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 5900 ]; # open vnc port on tailscale interface for remote desktop
  #networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 3389 ]; # open rdp port on tailscale interface for remote desktop

  systemd.user.services = {
    "app-org.kde.discover.notifier@autostart".enable = false; # disable auto-update checker
    "app-org.kde.kalendarac@autostart".enable = false; # disable calendar launch
  };

}
