{ 
  config,
  lib,
  configLib,
  configVars,
  pkgs, 
  nixServiceRecoveryScript,
  ... 
}: 

let

  app = "vaultwarden";
  appPort = 8222;
  recoveryPlan = {
    restoreItems = [
      "/var/lib/${app}"
      "/var/backup/postgresql/${app}.sql.gz"
    ];
    db = {
      type = "postgresql";
      user = app;
      name = app;
      dump = "/var/backup/postgresql/${app}.sql.gz";
    };
    stopServices = [ "${app}" ];
    startServices = [ "${app}" ];
  };
  recoverScript = nixServiceRecoveryScript {
    serviceName = app;
    recoveryPlan = recoveryPlan;
    dbType = recoveryPlan.db.type;
  };

in

{

  sops = {
    secrets = {
      chrisEmailPasswd = {};
    };
    templates = {
      "${app}-env".content = ''
        DOMAIN=https://${app}.${configVars.domain2}
        ROCKET_ADDRESS=127.0.0.1
        ROCKET_PORT=${toString appPort}
        ROCKET_LOG=critical
        DATABASE_URL=postgresql://${app}@/${app}
        SIGNUPS_ALLOWED=false
        SMTP_HOST=${configVars.mailservers.namecheap.smtpHost}
        SMTP_FROM=${configVars.users.chris.email}
        SMTP_FROM_NAME=${app}
        SMTP_SECURITY=starttls
        SMTP_PORT=${toString configVars.mailservers.namecheap.smtpPort}
        SMTP_USERNAME=${configVars.users.chris.email}
        SMTP_PASSWORD=${config.sops.placeholder.chrisEmailPasswd}
        SMTP_TIMEOUT=15
        SMTP_EMBED_IMAGES=true
        SMTP_AUTH_MECHANISM=Login
        ADMIN_TOKEN=$argon2id$v=19$m=65540,t=3,p=4$TkZqT1Zpb3dnQ0hKcG10RjZOUFZHWTZFOVhlTFk3bVNNYlM0bFdHb3kzZz0$fzWizVbndJKOqEeuQ9GKNyorXZVe7rloQBKn4VEKiu4
      '';
    };
  };

  environment.systemPackages = with pkgs; [ recoverScript ];

  systemd.services."${app}" = {
    requires = [ "postgresql.target" ];
    after = [ "postgresql.target" ];
  };
  
  backups.serviceHooks = {
    preHook = lib.mkAfter [
      "systemctl stop ${app}.service"
      "sleep 2"
      "systemctl start postgresqlBackup-${app}.service"
    ];
    postHook = lib.mkAfter [
      "systemctl start ${app}.service"
    ];
  };

  services = {

    ${app} = {
      enable = true;
      dbBackend = "postgresql";
      backupDir = null;
      environmentFile = config.sops.templates."${app}-env".path;
    };

    postgresql = {
      ensureDatabases = [ "${app}" ];
      ensureUsers = [
        {
          name = "${app}";
          ensureDBOwnership = true;
        }
      ];
    };

    postgresqlBackup.databases = [ "${app}" ];
    
    borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;
    
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
              url = "http://127.0.0.1:${toString appPort}";
            }
          ];
        };
      };
    };

  };

}