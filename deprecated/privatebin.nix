{
  pkgs,
  lib,
  config,
  configVars,
  ...
}: 

let
  app = "privatebin";
in

{

  services = {

    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "blackbox.${configVars.domain1}" = {
          enableACME = false;
          forceSSL = false;
          listen = [
            {
              addr = "127.0.0.1"; 
              port = 6240;
            }
          ];
          root = "${config.services.privatebin.package}";
          locations = {
            "/" = {
              tryFiles = "$uri $uri/ /index.php?$query_string";
              index = "index.php";
              extraConfig = ''
                sendfile off;
              '';
            };
            "~ \\.php$" = {
              extraConfig = ''
                include ${config.services.nginx.package}/conf/fastcgi_params ;
                fastcgi_param SCRIPT_FILENAME $request_filename;
                fastcgi_param modHeadersAvailable true; #Avoid sending the security headers twice
                fastcgi_pass unix:${config.services.phpfpm.pools.privatebin.socket};
              '';
            };
          };
        };
      };
    };

    ${app} = {
      enable = true;
      group = "nginx";
      settings = {
        main = {
          name = "Bond Secure Pastebin";
          discussion = false;
          defaultformatter = "plalib.types.intext";
        };
        model.class = "Filesystem";
        model_options.dir = "/var/lib/privatebin/data";
      };    
    };

    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`blackbox.${configVars.domain1}`)";
        service = "${app}";
        middlewares = [
          "secure-headers"
          "authelia-dcbond"
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
            url = "http://127.0.0.1:6240";
          }
          ];
        };
      };
    };

  };

}