{ 
  config, 
  configVars,
  pkgs, 
  lib,
  ... 
}:

let
  app = "uptime-kuma";
in

{

  services.${app}.enable = true;

  services.traefik.dynamicConfigOptions.http = {
    routers.${app} = {
      entrypoints = ["websecure"];
      rule = "Host(`${app}.${configVars.domain3}`)";
      service = "${app}";
      middlewares = [
        "authelia"
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
          url = "http://127.0.0.1:3001";
        }
        ];
      };
    };
  };

}