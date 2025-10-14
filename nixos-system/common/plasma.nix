{ 
  pkgs,
  ... 
}: 

{

  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      enable = true;
      #package = pkgs.kdePackages.sddm;
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

  environment = {
    systemPackages = with pkgs; [
      kdePackages.sddm-kcm # configuration module for sddm
      wayland-utils # wayland utilities
      wl-clipboard # command-line copy/paste utilities for wayland
    ];
    #plasma6.excludePackages = with pkgs.kdePackages; [
    #  plasma-browser-integration
    #  plasma-systemmonitor
    #  konsole
    #  kate
    #];
  };

}
