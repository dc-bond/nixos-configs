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
      #(pkgs.makeDesktopItem {
      #  name = "wifi";
      #  desktopName = "WiFi Connection Script";
      #  exec = "${pkgs.alacritty}/bin/alacritty -e wifi";
      #  icon = "network-wireless";
      #  type = "Application";
      #  categories = [ "Network" "System" ];
      #})
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
  };

  #networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 5900 ]; # open vnc port on tailscale interface for remote desktop
  #networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 3389 ]; # open rdp port on tailscale interface for remote desktop

  systemd.user.services = {
    "app-org.kde.discover.notifier@autostart".enable = false; # disable auto-update checker
    "app-org.kde.kalendarac@autostart".enable = false; # disable calendar launch
  };

}
