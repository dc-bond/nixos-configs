{ 
  config, 
  pkgs, 
  configVars,
  ... 
}: 

{

  #networking.firewall.allowedTCPPorts = [ 1883 ]; # not needed if homeassistant accessing through localhost, potentially needed for outside machines to connect

  sops.secrets.mqttHassPasswd = {};

  services = {

    mosquitto = {
      enable = true;
      logType = [ "error" ];
      logDest = [ "syslog" ];
      listeners = [
        {
          users.hass = {
            acl = [ "readwrite #" ];
            passwordFile = "${config.sops.secrets.mqttHassPasswd.path}";
          };
        }
      ];
    };

  };

}