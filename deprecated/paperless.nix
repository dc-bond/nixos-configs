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
  };

  systemd = {
    services = {
      "${app}-scheduler" = {
        requires = [ "postgresql.target" ];
        after = [ "postgresql.target" ];
      };
    };
    tmpfiles.rules = [
      "d /srv/${app}/consumption 2770 ${app} ${app}-ingest - -"
    ];
  };

  users.groups."${app}-ingest".members = [ "${app}" "chris" ];

  services = {

    ${app} = {
      enable = true;
      dataDir = "/var/lib/${app}/data";
      mediaDir = "/var/lib/${app}/media";
      consumptionDir = "/srv/${app}/consumption";
      user = "${app}";
      database.createLocally = false; # manually set below
      passwordFile = "${config.sops.secrets.paperlessAdminPasswd.path}";
      configureTika = true;
      settings = {
        PAPERLESS_ADMIN_USER = "${configVars.users.chris.email}";
        PAPERLESS_REDIS = "unix:///run/redis-${app}/redis.sock";
        PAPERLESS_DBHOST = "/run/postgresql";
        PAPERLESS_DBENGINE = "postgresql";
        PAPERLESS_DBPORT = "5432";
        PAPERLESS_DBNAME = "${app}";
        PAPERLESS_DBUSER = "${app}";  
        PAPERLESS_GOTENBERG_URL = "http://127.0.0.1:${toString config.services.gotenberg.port}";
        PAPERLESS_URL = "https://${app}.${configVars.domain2}";
        PAPERLESS_APP_TITLE = "Bond Digital Archives";
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