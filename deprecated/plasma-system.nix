{ 
  inputs,
  pkgs,
  config,
  ... 
}: 

{

  home-manager.sharedModules = [ inputs.plasma-manager.homeModules.plasma-manager ]; # make plasma-manager available to home-manager

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

  services.desktopManager.plasma6.enable = true;

  #networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 5900 ]; # open vnc port on tailscale interface for remote desktop
  #networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 3389 ]; # open rdp port on tailscale interface for remote desktop

  systemd.user.services = {
    "app-org.kde.discover.notifier@autostart".enable = false; # disable auto-update checker
    "app-org.kde.kalendarac@autostart".enable = false; # disable calendar launch
  };

}
