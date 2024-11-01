{ 
  config, 
  configVars,
  pkgs, 
  lib,
  ... 
}:

let
  app = "stirling-pdf";
in

{

  services.${app} = {
    enable = true;
    environment = {
      SERVER_PORT = 2000;
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.${app} = {
      entrypoints = ["websecure"];
      rule = "Host(`${app}.${configVars.domain3}`)";
      service = "${app}";
      middlewares = [
        #"authelia" 
        "secure-headers"
      ];
      tls = {
        certResolver = "cloudflareDns";
        options = "tls-13@file";
      };
    };
    services.${app} = {
      loadBalancer = {
        passHostHeader = true;
        servers = [
        {
          url = "http://localhost:2000";
        }
        ];
      };
    };
  };

}