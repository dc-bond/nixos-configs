{ 
  pkgs,
  lib,
  config, 
  configVars,
  ... 
}: 

let
  app = "n8n";
in

{
  
  systemd.services."${app}" = {
    requires = [ "postgresql.target" ];
    after = [ "postgresql.target" ];
  };

  services = {

    "${app}" = {
      enable = true;  
      settings = {
        N8N_LOG_LEVEL = "info";
        N8N_DIAGNOSTICS_ENABLED = false;
        N8N_VERSION_NOTIFICATIONS_ENABLED = false;
        N8N_TEMPLATES_ENABLED = false;
        DB_TYPE = "postgresdb";
        DB_POSTGRESDB_DATABASE = "${app}";
        DB_POSTGRESDB_HOST = "127.0.0.1";
        DB_POSTGRESDB_PORT = 5432;
        DB_POSTGRESDB_USER = "${app}";
        N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = true;
        DOMAIN_NAME = "${configVars.domain2}";
        SUBDOMAIN = "${app}";
        N8N_HOST = "${app}.${configVars.domain2}";
        N8N_PORT = 5678;
        N8N_PROTOCOL = "https";
        N8N_RUNNERS_ENABLED = true;
        NODE_ENV = "production";
        WEBHOOK_URL = "https://${app}.${configVars.domain2}/";
      };
    };

    postgresql = {
      ensureDatabases = ["${app}"];
      ensureUsers = [
        {
          name = "${app}";
          ensureDBOwnership = true;
          ensureClauses.createdb = true;
        }
      ];
    };

    postgresqlBackup = {
      databases = ["${app}"];
    };

    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [
          "trusted-allow"
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
            url = "http://127.0.0.1:5678";
          }
          ];
        };
      };
    };

  };

}