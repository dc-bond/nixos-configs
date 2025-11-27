{ 
  pkgs,
  config,
  configVars,
  lib,
  ... 
}: 

{

  environment.systemPackages = with pkgs; [
    wayland
  ];

  programs = {
    wayland.enable = true;
    labwc.enable = true;
  };

  # create session file so tuigreet can discover and launch labwc
  services.displayManager.sessionPackages = [ 
    (pkgs.writeTextFile {
      name = "labwc-session";
      destination = "/share/wayland-sessions/labwc.desktop";
      text = ''
        [Desktop Entry]
        Name=labwc
        Comment=Stacking Wayland compositor
        Exec=${pkgs.labwc}/bin/labwc
        Type=Application
      '';
    })
  ];

}
