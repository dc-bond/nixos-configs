{ 
  pkgs,
  lib,
  config,
  configVars,
  inputs,
  ... 
}: 

let
  app = "finplanner";
in

{

  imports = [ inputs.finplanner.nixosModules.default ];
  
  services = {

    ${app} = {
      enable = true;
      port = 8502;
      address = "127.0.0.1";
    };

    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [
          "secure-headers"
          "trusted-allow"
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
            url = "http://127.0.0.1:8502";
          }
          ];
        };
      };
    };

  };

}