{ 
  pkgs, 
  config,
  configVars,
  ...
}: 

let
  app = "paperless";
in

{

  sops = {
    secrets = {
      paperlessAdminPasswd = {};
    };
    #templates = {
    #  "${app}-env".content = ''
    #    POSTGRES_DB=${config.sops.placeholder.recipesagePostgresDb}
    #    POSTGRES_USER=${config.sops.placeholder.recipesagePostgresUser}
    #    POSTGRES_PASSWORD=${config.sops.placeholder.recipesagePostgresPasswd}
    #    POSTGRES_PORT=5432
    #    POSTGRES_HOST=${app6}
    #    POSTGRES_SSL=false
    #    POSTGRES_LOGGING=false
    #    DATABASE_URL=postgresql://${config.sops.placeholder.recipesagePostgresUser}:${config.sops.placeholder.recipesagePostgresPasswd}@${app6}:5432/${config.sops.placeholder.recipesagePostgresDb}
    #  '';
    #  "${app}-passwd".content = ''
    #    ${config.sops.placeholder.paperlessAdminPasswd}
    #  '';
    #};
  };

  services = {

    ${app} = {
      enable = true;
      dataDir = "/var/lib/paperless/data";
      mediaDir = "/var/lib/paperless/media";
      consumptionDir = "/var/lib/paperless/consumption";
      user = "${app}";
      database.createLocally = false; # manually set below
      #environmentFile = [ config.sops.templates."${app}-env".path ];
      passwordFile = "${config.sops.secrets.paperlessAdminPasswd.path}";
      #passwordFile = [ config.sops.templates."${app}-passwd".path ];
      configureTika = true;
      settings = {
        PAPERLESS_ADMIN_USER = "${configVars.userEmail}";
        PAPERLESS_REDIS = "redis://127.0.0.1:6379";
        PAPERLESS_DBHOST = "127.0.0.1";
        PAPERLESS_DBENGINE = "postgresql";
        PAPERLESS_DBPORT = "5432";
        PAPERLESS_DBNAME = "${app}";
        PAPERLESS_DBUSER = "${app}";  
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
              url = "http://127.0.0.1:28981";
            }
          ];
        };
      };
    };
  
  };

}