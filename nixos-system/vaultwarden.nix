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
        DOMAIN=https://${app}.${configVars.domain1}
        ROCKET_ADDRESS=127.0.0.1
        ROCKET_PORT=${toString appPort}
        ROCKET_LOG=critical
        DATABASE_URL=postgresql://${app}@/${app}
        SIGNUPS_ALLOWED=false
        WEBSOCKET_ENABLED=true
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
      '';
        #ADMIN_TOKEN=$argon2id$v=19$m=65540,t=3,p=4$TkZqT1Zpb3dnQ0hKcG10RjZOUFZHWTZFOVhlTFk3bVNNYlM0bFdHb3kzZz0$fzWizVbndJKOqEeuQ9GKNyorXZVe7rloQBKn4VEKiu4
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
      # fail-fast on dump errors so silent DB backup failures surface via the existing
      # OnFailure email/ntfy path instead of borg archiving a stale .prev.sql.gz
      "systemctl start --wait postgresqlBackup-${app}.service || exit 1"
      "test -s /var/backup/postgresql/${app}.sql.gz || exit 1"
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
      # main router - public access for API and web vault
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain1}`) && !PathPrefix(`/admin`)";
        service = "${app}";
        middlewares = [
          "maintenance-page"
          "${app}-headers"
        ];
        tls = {
          certResolver = "cloudflareDns";
          options = "tls-13@file";
        };
      };
      # admin-only router - restricted to trusted IPs
      routers."${app}-admin" = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain1}`) && PathPrefix(`/admin`)";
        service = "${app}";
        middlewares = [
          "maintenance-page"
          "forbidden-page"
          "trusted-allow"
          "${app}-headers"
        ];
        tls = {
          certResolver = "cloudflareDns";
          options = "tls-13@file";
        };
        priority = 100;
      };
      # vaultwarden-specific middleware without CSP and frameDeny (vaultwarden needs iframes for WebAuthn)
      middlewares."${app}-headers" = {
        headers = {
          sslRedirect = true;
          accessControlMaxAge = "100";
          stsSeconds = "31536000";
          stsIncludeSubdomains = true;
          stsPreload = true;
          forceSTSHeader = true;
          contentTypeNosniff = true;
          browserXssFilter = true;
          referrerPolicy = "same-origin";
          addVaryHeader = true;
          customFrameOptionsValue = "SAMEORIGIN";
        };
      };
      # single service definition shared by both routers
      services.${app} = {
        loadBalancer = {
          serversTransport = "default";
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