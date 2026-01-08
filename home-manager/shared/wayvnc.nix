{
  pkgs,
  ...
}:

{

  services.wayvnc = {
    enable = true;
    package = pkgs.wayvnc;
    autoStart = true; # start with desktop session
    systemdTarget = "graphical-session.target"; # bind to graphical session
    settings = {
      address = "127.0.0.1"; # localhost only - secure via SSH tunnel
      port = 5900; # default VNC port
    };
  };
  
}
