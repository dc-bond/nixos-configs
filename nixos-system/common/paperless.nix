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
      paperlessPostgresPasswd = {};
    };
    #templates = {
    #  "${app}-env".content = ''
    #    PAPERLESS_DBPASS=${config.sops.placeholder.paperlessPostgresPasswd}
    #  '';
    #};
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
      database.createLocally = false; # manually set below
      #environmentFile = "${config.sops.templates."${app}-env".path}";
      passwordFile = "${config.sops.secrets.paperlessAdminPasswd.path}";
      configureTika = true;
      settings = {
        PAPERLESS_ADMIN_USER = "${configVars.userEmail}";
        PAPERLESS_REDIS = "redis-${app}://127.0.0.1:6379";
        PAPERLESS_DBHOST = "127.0.0.1";
        PAPERLESS_DBENGINE = "postgresql";
        PAPERLESS_DBPORT = "5432";
        PAPERLESS_DBNAME = "${app}";
        PAPERLESS_DBUSER = "${app}";  
        PAPERLESS_DBPASS = "${config.sops.placeholder.paperlessPostgresPasswd}";
      };
    };

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