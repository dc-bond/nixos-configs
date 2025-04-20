{ 
pkgs,
config,
configVars, 
lib,
... 
}: 

let
  app = "kasmweb";
in

{

  services = {

    ${app} = {
      enable = true;
      networkSubnet = "${configVars.kasmwebSubnet}";
      listenAddress = "127.0.0.1";
      listenPort = 8377;
    };

    traefik = {
      staticConfigOptions.serversTransport.insecureSkipVerify = true; 
      dynamicConfigOptions.http = {
        routers.${app} = {
          entrypoints = ["websecure"];
          rule = "Host(`${app}.${configVars.domain2}`)";
          service = "${app}";
          middlewares = [ "secure-headers" ];
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
              url = "https://127.0.0.1:8377";
            }
            ];
          };
        };
      };
    };

  };

}