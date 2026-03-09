{
  pkgs,
  lib,
  config,
  configVars,
  ...
}:

let
  app = "calibre-web";
in

{

  services = {

    "${app}" = {
      enable = true;
      user = "calibre-web";
      group = "calibre-web";
      listen = {
       ip = "127.0.0.1";
       port = 7190;
      };
      options = {
        reverseProxyAuth.enable = true;
        calibreLibrary = "${config.bulkStorage.path}/media/library/ebooks/calibre/";
        enableBookUploading = true;
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers = {
        ${app} = {
          entrypoints = ["websecure"];
          rule = "Host(`${app}.${configVars.domain2}`)";
          service = "${app}";
          middlewares = [
            "maintenance-page"
            "trusted-allow"
            "secure-headers"
            "forbidden-page"
          ];
          tls = {
            certResolver = "cloudflareDns";
            options = "tls-13@file";
          };
        };
      };
      services = {
        ${app} = {
          loadBalancer = {
            serversTransport = "default";
            passHostHeader = true;
            servers = [
            {
              url = "http://127.0.0.1:7190";
            }
            ];
          };
        };
      };
    };

  };

}