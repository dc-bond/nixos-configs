{ 
pkgs,
config,
configVars, 
lib,
... 
}: 

let
  app = "roundcube";
in

{

  services = {

    nginx = {
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."${app}.${configVars.domain2}".listen = [{addr = "127.0.0.1"; port = 4415;}];
    };

    ${app} = {
      enable = true;
      configureNginx = true;
      hostName = "${app}.${configVars.domain2}";
      maxAttachmentSize = 30;
      dicts = with pkgs.aspellDicts; [ en ];
      database.host = "127.0.0.1";
      databse.username = "${app}";
      databse.dbname = "${app}";
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
            url = "http://127.0.0.1:4415";
          }
          ];
        };
      };
    };

  };

}