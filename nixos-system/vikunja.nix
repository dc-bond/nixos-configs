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

  app = "vikunja";
  appPort = 3456;
  recoveryPlan = {
    restoreItems = [
      "/var/lib/private/${app}"
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
      vikunjaJwtSecret = {};
      chrisEmailPasswd = {};
    };
    templates = {
      "${app}-env".content = ''
        VIKUNJA_SERVICE_SECRET=${config.sops.placeholder.vikunjaJwtSecret}
        VIKUNJA_MAILER_PASSWORD=${config.sops.placeholder.chrisEmailPasswd}
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
      frontendScheme = "https";
      frontendHostname = "${app}.${configVars.domain2}";
      port = appPort;
      environmentFiles = [
        config.sops.templates."${app}-env".path
      ];
      database = {
        type = "postgres";
        host = "/run/postgresql"; # unix socket -> peer auth as user "vikunja"
        user = "${app}";
        database = "${app}";
      };
      settings = {
        service = {
          enableregistration = false;
        };
        files = {
          maxsize = "50MB";
        };
        log = {
          level = "INFO";
        };
        mailer = {
          enabled = true;
          host = configVars.mailservers.namecheap.smtpHost;
          port = configVars.mailservers.namecheap.smtpPort;
          authtype = "login";
          username = configVars.users.chris.email;
          fromemail = "task-reminders@dcbond.com";
          forcessl = false;
          skiptlsverify = false;
        };
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

    postgresqlBackup = { databases = [ "${app}" ]; };

    borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;

    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [
          "maintenance-page"
          "trusted-allow"
          "secure-headers"
          "forbidden-page"
        ];
        tls = {
          certResolver = "cloudflareDns";
          options = "tls-13@file";
        };
      };
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