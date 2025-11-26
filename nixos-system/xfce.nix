{ 
  pkgs,
  config,
  configVars,
  lib,
  ... 
}: 

{

  services = {
    displayManager.sessionPackages = [ pkgs.xfce.xfce4-session ];
    xserver = {
      enable = true;
      desktopManager.xfce = {
        enable = true;
        #enableWaylandSession = true;
        enableXfwm = true;
        enableScreensaver = false;
        noDesktop = false;  # show desktop icons and background
      };
    };
    libinput = {
      enable = true; # enable mouse support in x11
      touchpad = {
        tapping = true;
        naturalScrolling = true;  # optional
      };
    };
    #gnome.gnome-keyring.enable = true;
    gvfs.enable = true; # mount, trash, and other functionalities
    tumbler.enable = true; # thumbnail support for images
  };

  programs = {
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
    xfconf.enable = true;
  };

   environment.xfce.excludePackages = with pkgs.xfce; [
     xfce4-screensaver
     parole  # media player
   ];

  # programs.gnupg.agent.pinentryPackage = pkgs.pinentry-gtk2;

  environment.systemPackages = with pkgs; [
    xfce.xfce4-pulseaudio-plugin
    xfce.xfce4-whiskermenu-plugin
    xorg.xinit # required for startxfce4 x11
  ];

}
