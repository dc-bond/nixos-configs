{ 
  pkgs,
  config,
  configVars,
  lib,
  ... 
}: 

{

  services = {
    displayManager = {
      sessionPackages = [ pkgs.lxqt.lxqt-session ];
      defaultSession = "lxqt";
    };
    xserver = {
      enable = true;
      desktopManager.lxqt = {
        enable = true;
      };
    };
    libinput = {
      enable = true; # enable mouse support in x11
      touchpad = {
        tapping = true;
        naturalScrolling = true;  # optional
      };
    };
  };

  qt.platformTheme = "lxqt";

}
