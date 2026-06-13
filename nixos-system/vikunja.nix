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
    };
    templates = {
      "${app}-env".content = ''
        VIKUNJA_SERVICE_JWTSECRET=${config.sops.placeholder.vikunjaJwtSecret}
      '';
    };
  };

  systemd.services.${app} = {
    requires = [ "postgresql.target" ];
    after = [ "postgresql.target" ];
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
        user = app;
        database = app;
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
      };
    };

    postgresql = {
      ensureDatabases = [ app ];
      ensureUsers = [
        {
          name = app;
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };

    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = [ "websecure" ];
        rule = "Host(`${app}.${configVars.domain2}`)";
        service = app;
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
            { url = "http://127.0.0.1:${toString appPort}"; }
          ];
        };
      };
    };

  };

  # ---------------------------------------------------------------------------
  # Phase 2: enable after smoke test passes
  # ---------------------------------------------------------------------------
  # Backup integration: dump postgres + include state dir in borgbackup.
  # Homepage tile lives in nixos-system/homepage.nix; uncomment the block there
  # at the same time as enabling these.
  #
  # environment.systemPackages = with pkgs; [ recoverScript ];
  #
  # backups.serviceHooks = {
  #   preHook = lib.mkAfter [
  #     "systemctl stop ${app}.service"
  #     "sleep 2"
  #     "systemctl start postgresqlBackup-${app}.service"
  #     "while systemctl is-active --quiet postgresqlBackup-${app}.service; do sleep 1; done"
  #   ];
  #   postHook = lib.mkAfter [
  #     "systemctl start ${app}.service"
  #   ];
  # };
  #
  # services.postgresqlBackup.databases = [ app ];
  # services.borgbackup.jobs."${config.networking.hostName}".paths =
  #   lib.mkAfter recoveryPlan.restoreItems;

}
