{ 
  pkgs,
  config,
  configVars,
  lib,
  ... 
}: 

{

  environment.systemPackages = with pkgs; [
    wl-clipboard # command-line copy/paste utilities for wayland
  ];

  programs = {
    labwc.enable = true;
  };

  #services.displayManager.sessionPackages = [ 
  #  (pkgs.writeTextFile {
  #    name = "labwc-session";
  #    destination = "/share/wayland-sessions/labwc.desktop";
  #    text = ''
  #      [Desktop Entry]
  #      Name=labwc
  #      Comment=Stacking Wayland compositor
  #      Exec=${pkgs.labwc}/bin/labwc
  #      Type=Application
  #    '';
  #  })
  #];

}
