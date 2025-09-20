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

  sops.secrets = {
    paperlessAdminPasswd = {};
    paperlessPostgresPasswd = {};
  };

  systemd.services = {
    "${app}-scheduler" = {
      requires = [ "postgresql.service" ];
      after = [ "postgresql.service" ];
    };
  };

  services = {

    ${app} = {
      enable = true;
      dataDir = "/var/lib/paperless/data";
      mediaDir = "/var/lib/paperless/media";
      consumptionDir = "/var/lib/paperless/consumption";
      user = "${app}";
      address = "https://paperless.${configVars.domain2}";
      database.createLocally = false; # manually set below
      passwordFile = "${config.sops.secrets.paperlessAdminPasswd.path}";
      configureTika = true;
      settings = {
        PAPERLESS_ADMIN_USER = "${configVars.userEmail}";
        PAPERLESS_REDIS = "/run/redis-${app}/redis.sock";
        PAPERLESS_DBHOST = "/run/postgresql";
        PAPERLESS_DBENGINE = "postgresql";
        PAPERLESS_DBPORT = "5432";
        PAPERLESS_DBNAME = "${app}";
        PAPERLESS_DBUSER = "${app}";  
        PAPERLESS_GOTENBERG_URL = "http://127.0.0.1:${toString config.services.gotenberg.port}";
      };
    };

    gotenberg.port = 3277;

    redis.servers."${app}" = { # service name will be "redis-paperless"
      enable = true;
      user = "${app}";   
      port = 0;
      unixSocket = "/run/redis-${app}/redis.sock";
      unixSocketPerm = 600;
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