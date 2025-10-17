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
      kate
      khelpcenter
      konsole
      krdp
      plasma-browser-integration
      plasma-systemmonitor
      xwaylandvideobridge
    ];
  };

  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      enable = true;
      enableHidpi = true;
      wayland.enable = true;
      #autoNumlock = true;
      #settings = {
      #  Autologin = {
      #    Session = "hyprland.desktop";
      #    User = "chris";
      #  };
      #};
    };
  };

  systemd.user.services = {
    "app-org.kde.discover.notifier@autostart".enable = false; # disable auto-update checker
    "app-org.kde.kalendarac@autostart".enable = false; # disable calendar launch
  };

}
