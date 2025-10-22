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
      sddm-chili-theme
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
      theme = "sddm-chili-theme";
    };
    #xrdp = {
    #  enable = true;
    #  defaultWindowManager = "startplasma-x11";
    #  openFirewall = true; # opens port 3389
    #};
    #xserver = {
    #  enable = true;
    #  xkb = {
    #    layout = "us";
    #    variant = "";
    #  };
    #};
  };

  systemd.user.services = {
    "app-org.kde.discover.notifier@autostart".enable = false; # disable auto-update checker
    "app-org.kde.kalendarac@autostart".enable = false; # disable calendar launch
  };

}
