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
  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";
  recoveryPlan = {
    serviceName = "${app}";
    localRestoreRepoPath = "${config.backups.borgDir}/${config.networking.hostName}";
    cloudRestoreRepoPath = "${config.backups.borgCloudDir}/${config.networking.hostName}";
    restoreItems = [
      "/var/lib/bitwarden_rs"
      "/var/backup/postgresql/vaultwarden.sql.gz"
    ];
    db = {
      type = "postgresql";
      user = "vaultwarden";
      name = "vaultwarden";
      dump = "/var/backup/postgresql/vaultwarden.sql.gz";
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
      borgCryptPasswd = {};
      chrisEmailPasswd = {};
      vaultwardenAdminToken = {};
    };
    templates = {
      "${app}-env".content = ''
        DOMAIN=https://${app}.${configVars.domain2}
        ROCKET_ADDRESS=127.0.0.1
        ROCKET_PORT=${toString appPort}
        ROCKET_LOG=critical
        DATABASE_URL=postgresql://vaultwarden@/vaultwarden
        SIGNUPS_ALLOWED=false
        SMTP_HOST=${configVars.mailservers.namecheap.smtpHost}
        SMTP_FROM=vaultwarden@${configVars.domain2}
        SMTP_FROM_NAME=Vaultwarden
        SMTP_SECURITY=starttls
        SMTP_PORT=${toString configVars.mailservers.namecheap.smtpPort}
        SMTP_USERNAME=${configVars.users.chris.email}
        SMTP_PASSWORD=${config.sops.placeholder.chrisEmailPasswd}
        SMTP_TIMEOUT=15
        SMTP_EMBED_IMAGES=true
        ADMIN_TOKEN=${config.sops.placeholder.vaultwardenAdminToken}
      '';
    };
  };

  environment.systemPackages = with pkgs; [ recoverScript ];

  systemd.services."${app}" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };
  
  backups.serviceHooks = {
    preHook = lib.mkAfter [
      "systemctl stop ${app}.service"
      "sleep 2"
      "systemctl start postgresqlBackup-vaultwarden.service"
    ];
    postHook = lib.mkAfter [
      "systemctl start ${app}.service"
    ];
  };

  services = {

    ${app} = {
      enable = true;
      dbBackend = "postgresql";
      backupDir = "/var/backup/vaultwarden";
      environmentFile = config.sops.templates."${app}-env".path;
    };

    postgresql = {
      ensureDatabases = [ "vaultwarden" ];
      ensureUsers = [
        {
          name = "vaultwarden";
          ensureDBOwnership = true;
        }
      ];
    };

    postgresqlBackup.databases = [ "vaultwarden" ];
    
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