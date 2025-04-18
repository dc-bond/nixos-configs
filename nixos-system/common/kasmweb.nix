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
      listenPort = 4432;
    };
    
    postgresqlBackup = {
      databases = [ "${app}" ];
    };

    traefik.dynamicConfigOptions.http = {
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
            url = "http://127.0.0.1:4432";
          }
          ];
        };
      };
    };

  };

}