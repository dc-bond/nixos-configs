{ 
pkgs,
config,
configVars, 
lib,
... 
}: 

{

  services = {

    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {

        "weekly-recipes.${configVars.domain2}" = {
          enableACME = false;
          forceSSL = false;
          root = "/var/www/weekly-recipes.opticon.dev";
          listen = [
            {
              addr = "127.0.0.1"; 
              port = 9016;
            }
          ];
        };
        
      };
    };
       
    traefik = {

      dynamicConfigOptions.http = {
        routers = {

          "weekly-recipes" = {
            entrypoints = ["websecure"];
            rule = "Host(`weekly-recipes.${configVars.domain2}`)";
            service = "weekly-recipes";
            middlewares = [
              "trusted-allow"
              "secure-headers"
            ];
            tls = {
              certResolver = "cloudflareDns";
              options = "tls-13@file";
            };
          };
        };

        services = {

          "weekly-recipes" = {
            loadBalancer = {
              passHostHeader = true;
              servers = [
                {
                  url = "http://127.0.0.1:9016";
                }
              ];
            };
          };
          
        };
      };
    };

  };

}