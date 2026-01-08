{
  pkgs,
  ...
}:

{

  services.wayvnc = {
    enable = true;
    package = pkgs.wayvnc;
    autoStart = false; # started manually from labwc autostart (needs WAYLAND_DISPLAY)
    settings = {
      address = "127.0.0.1"; # localhost only - secure via SSH tunnel
      port = 5900; # default VNC port
    };
  };
  
}
