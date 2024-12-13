{ 
  config, 
  pkgs, 
  configVars,
  ... 
}: 

{

  services = {

    mosquitto = {
      enable = true;
      logType = [ "error" ];
    };

  };

}