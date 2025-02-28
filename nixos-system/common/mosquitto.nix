{ 
  config, 
  pkgs, 
  configVars,
  ... 
}: 

{

  #networking.firewall.allowedTCPPorts = [ 1883 ]; # not needed if homeassistant accessing through localhost, potentially needed for outside machines to connect

  services = {

    mosquitto = {
      enable = true;
      logType = [ "error" ];
      logDest = [ "syslog" ];
    };

  };

}