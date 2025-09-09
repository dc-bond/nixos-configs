{
  pkgs,
  config,
  configVars,
  ...
}: 

let

  app = "writefreely";

in

{
  
  sops.secrets = {
    writefreelyAdminPasswd = {
      owner = config.users.users."${app}".name;
      group = config.users.users."${app}".group;
      mode = "0440";
    };
    writefreelyDbPasswd = { 
      owner = config.users.users."${app}".name;
      group = config.users.users."${app}".group;
      mode = "0440";
    };
  };

  services = {

    "${app}" = {
      enable = true;
      settings = {
        server.port = 5312;
        app.theme = "write";
      };
      host = "travelplanning.${configVars.domain2}";
      database = {
        type = "mysql";
        user = "${app}";
        name = "${app}";
        port = 3306;
        migrate = true;
        host = "127.0.0.1";
        passwordFile = "${config.sops.secrets.writefreelyDbPasswd.path}";
        createLocally = true;
      };
      admin = {
        name = "${configVars.userEmail}";
        initialPasswordFile = "${config.sops.secrets.writefreelyAdminPasswd.path}";
      };
    };

    #mysql = {
    #  ensureDatabases = ["${app}"];
    #  ensureUsers = [
    #    {
    #      name = "${app}";
    #      ensurePermissions = { "${app}.*" = "ALL PRIVILEGES"; };
    #    }
    #  ];
    #};

    mysqlBackup = { databases = ["${app}"]; };

    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`travelplanning.${configVars.domain2}`)";
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
            url = "http://127.0.0.1:5312";
          }
          ];
        };
      };
    };

  };

}