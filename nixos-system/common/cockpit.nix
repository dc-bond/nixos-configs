{ 
  config, 
  configVars,
  pkgs, 
  lib,
  ... 
}:

let
  app = "cockpit";
in

{

  services.${app}.enable = true;

  services.traefik.dynamicConfigOptions.http = {
    routers.${app} = {
      entrypoints = ["websecure"];
      rule = "Host(`${app}.${configVars.domain3}`)";
      service = "${app}";
      middlewares = [
        "auth-chain"
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
          url = "http://localhost:9090";
        }
        ];
      };
    };
  };

}