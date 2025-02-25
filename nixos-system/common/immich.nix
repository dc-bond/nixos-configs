{
  pkgs,
  lib,
  config,
  configVars,
  ...
}: 

let
  app = "immich";
in

{

  services = {

    ${app} = {
      enable = true;
      #package = pkgs.unstable.immich;
      redis.enable = true;
      environment = {
        IMMICH_LOG_LEVEL = "verbose";
      };
    };

    postgresql = {
      ensureDatabases = [ "${app}" ];
      ensureUsers = [
        {
          name = "${app}";
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };

    postgresqlBackup = {
      databases = [ "${app}" ];
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
            url = "http://127.0.0.1:2283";
          }
          ];
        };
      };
    };

  };

}