{ 
  config,
  lib,
  pkgs, 
  configVars,
  dockerServiceRecoveryScript,
  ... 
}: 

let

  app = "n8n";
  recoveryPlan = {
    restoreItems = [
      "/var/lib/docker/volumes/${app}"
      "/var/lib/docker/volumes/${app}-postgres"
    ];
    stopServices = [ "docker-${app}-root.target" ];
    startServices = [ "docker-${app}-root.target" ];
  };
  recoverScript = dockerServiceRecoveryScript {
    serviceName = app;
    recoveryPlan = recoveryPlan;
  };

in

{
  
  environment.systemPackages = with pkgs; [ recoverScript ];

  backups.serviceHooks = {
    preHook = lib.mkAfter [ "systemctl stop docker-${app}-root.target" ];
    postHook = lib.mkAfter [ "systemctl start docker-${app}-root.target" ];
  };

  services.borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;

  sops = {
    secrets = {
      n8nDbPasswd = {};
    };
    templates = {
      "${app}-env".content = ''
        N8N_LOG_LEVEL=info
        N8N_DIAGNOSTICS_ENABLED=false
        N8N_VERSION_NOTIFICATIONS_ENABLED=false
        N8N_TEMPLATES_ENABLED=false
        DB_TYPE=postgresdb
        DB_POSTGRESDB_DATABASE=${app}
        DB_POSTGRESDB_HOST=${app}-postgres
        DB_POSTGRESDB_PORT=5432
        DB_POSTGRESDB_USER=${app}
        DB_POSTGRESDB_PASSWORD=${config.sops.placeholder.n8nDbPasswd}
        N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
        DOMAIN_NAME=${configVars.domain2}
        SUBDOMAIN=${app}
        N8N_HOST=${app}.${configVars.domain2}
        N8N_PORT=5678
        N8N_PROTOCOL=https
        N8N_RUNNERS_ENABLED=true
        NODE_ENV=production
        WEBHOOK_URL=https://${app}.${configVars.domain2}/
        GENERIC_TIMEZONE=America/New_York
      '';
      "${app}-postgres-env".content = ''
        POSTGRES_USER=${app}
        POSTGRES_PASSWORD=${config.sops.placeholder.n8nDbPasswd}
        POSTGRES_DB=${app}
      '';
    };
  };

  virtualisation.oci-containers.containers = {

    "${app}" = {
      image = "docker.io/n8nio/n8n:2.0.1"; # https://hub.docker.com/r/n8nio/n8n
      autoStart = true;
      environmentFiles = [ config.sops.templates."${app}-env".path ];
      log-driver = "journald";
      volumes = [ "${app}:/home/node/.n8n" ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.n8nIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${app}.entrypoints" = "websecure";
        "traefik.http.routers.${app}.rule" = "Host(`${app}.${configVars.domain2}`)";
        "traefik.http.routers.${app}.tls" = "true";
        "traefik.http.routers.${app}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app}.middlewares" = "trusted-allow@file,secure-headers@file";
        "traefik.http.services.${app}.loadbalancer.server.port" = "5678";
      };
    };

    "${app}-postgres" = {
      image = "docker.io/library/postgres:18.0"; # https://hub.docker.com/_/postgres
      autoStart = true;
      environmentFiles = [ config.sops.templates."${app}-postgres-env".path ];
      log-driver = "journald";
      volumes = [ "${app}-postgres:/var/lib/postgresql" ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.n8nPostgresIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

  };

  systemd = {
    services = { 

      "docker-${app}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-volume-${app}.service"
          "docker-${app}-postgres.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}.service"
          "docker-${app}-postgres.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };

      "docker-network-${app}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${pkgs.docker}/bin/docker network rm -f ${app}";
        };
        script = ''
          docker network inspect ${app} || docker network create --subnet ${configVars.n8nSubnet} --driver bridge --scope local --attachable ${app}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };

      "docker-volume-${app}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app} || docker volume create ${app}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };
      
      "docker-${app}-postgres" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-volume-${app}-postgres.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}-postgres.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };

      "docker-volume-${app}-postgres" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app}-postgres || docker volume create ${app}-postgres
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };

    };
    
    targets."docker-${app}-root" = {
      unitConfig = {
        Description = "root target for docker-${app} and docker-${app}-postgres";
      };
      wantedBy = ["multi-user.target"];
    };
  }; 

}