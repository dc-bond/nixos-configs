{
  pkgs,
  lib,
  config,
  configVars,
  ...
}: 

let
  app = "calibre-server";
in

{

  services = {

    "${app}" = {
      enable = true;
      port = 7189;
      libraries = [ "${config.drives.storageDrive1}/media/ebooks/calibre" ];
    };

    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain2}`)";
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
            url = "http://127.0.0.1:7189";
          }
          ];
        };
      };
    };

  };

}