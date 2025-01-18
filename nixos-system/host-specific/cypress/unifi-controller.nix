{ 
  pkgs, 
  config,
  configVars,
  lib,
  ... 
}: 

let
  app = "unifi-controller";
in

{

  services.unifi = {
    enable = true;
    openFirewall = true;
    mongodbPackage = pkgs.mongodb-7_0;
  
    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`unifi-controller.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [
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
            url = "http://127.0.0.1:8443";
          }
          ];
        };
      };
    };

  };

}