{
  config,
  lib,
  pkgs,
  configVars,
  dockerServiceRecoveryScript,
  ...
}:

let

  app = "dawarich";
  app2 = "${app}-postgres";
  app3 = "${app}-redis";
  app4 = "${app}-sidekiq";

  recoveryPlan = {
    restoreItems = [
      "/var/lib/docker/volumes/${app}"
      "/var/lib/docker/volumes/${app2}"
      "/var/lib/docker/volumes/${app}-shared"
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
      dawarichDbPasswd = {};
      dawarichSecretKeyBase = {};
    };
    templates = {
      "${app}-env".content = ''
        RAILS_ENV=production
        SELF_HOSTED=true
        APPLICATION_HOSTS=${app}.${configVars.domain2}
        APPLICATION_PROTOCOL=https
        DATABASE_HOST=${app2}
        DATABASE_USERNAME=${app}
        DATABASE_PASSWORD=${config.sops.placeholder.dawarichDbPasswd}
        DATABASE_NAME=${app}
        DATABASE_PORT=5432
        REDIS_URL=redis://${app3}:6379
        RAILS_CACHE_DB=0
        RAILS_JOB_QUEUE_DB=1
        RAILS_WS_DB=2
        BACKGROUND_PROCESSING_CONCURRENCY=5
        SECRET_KEY_BASE=${config.sops.placeholder.dawarichSecretKeyBase}
        RAILS_MAX_THREADS=5
        TIME_ZONE=America/New_York
      '';
      "${app2}-env".content = ''
        POSTGRES_USER=${app}
        POSTGRES_PASSWORD=${config.sops.placeholder.dawarichDbPasswd}
        POSTGRES_DB=${app}
        POSTGRES_INITDB_ARGS=--encoding=UTF-8 --lc-collate=C --lc-ctype=C
      '';
    };
  };

  virtualisation.oci-containers.containers = {

    "${app2}" = {
      image = "docker.io/postgis/postgis:17-3.6"; # https://hub.docker.com/r/postgis/postgis/tags - PostgreSQL 17 + PostGIS 3.6
      autoStart = true;
      environmentFiles = [ config.sops.templates."${app2}-env".path ];
      log-driver = "journald";
      volumes = [ "${app2}:/var/lib/postgresql/data" ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.containerServices.${app}.containers.${app2}.ipv4}"
        "--tty=true"
        "--stop-signal=SIGINT"
        "--health-cmd=pg_isready -U ${app}"
        "--health-interval=10s"
        "--health-timeout=5s"
        "--health-retries=5"
      ];
    };

    "${app3}" = {
      image = "docker.io/library/redis:7-alpine"; # https://hub.docker.com/_/redis
      autoStart = true;
      log-driver = "journald";
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.containerServices.${app}.containers.${app3}.ipv4}"
        "--tty=true"
        "--stop-signal=SIGINT"
        "--health-cmd=redis-cli ping"
        "--health-interval=10s"
        "--health-timeout=5s"
        "--health-retries=5"
      ];
    };

    "${app}" = {
      image = "docker.io/freikin/dawarich:1.3.2"; # https://hub.docker.com/r/freikin/dawarich
      autoStart = true;
      environmentFiles = [ config.sops.templates."${app}-env".path ];
      log-driver = "journald";
      volumes = [
        "${app}:/var/app/data"
        "${app}-shared:/var/app/tmp"
      ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.containerServices.${app}.containers.${app}.ipv4}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

    "${app4}" = {
      image = "docker.io/freikin/dawarich:1.3.2"; # https://hub.docker.com/r/freikin/dawarich
      autoStart = true;
      cmd = [ "sidekiq" ];
      environmentFiles = [ config.sops.templates."${app}-env".path ];
      log-driver = "journald";
      volumes = [
        "${app}:/var/app/data"
        "${app}-shared:/var/app/tmp"
      ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.containerServices.${app}.containers.${app4}.ipv4}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

  };

  systemd = {
    services = {

      "docker-network-${app}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${pkgs.docker}/bin/docker network rm -f ${app}";
        };
        script = ''
          docker network inspect ${app} || docker network create --subnet ${configVars.containerServices.${app}.subnet} --driver bridge --scope local --attachable ${app}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };

      "docker-${app2}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-volume-${app2}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app2}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };

      "docker-volume-${app2}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app2} || docker volume create ${app2}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };

      "docker-${app3}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
        ];
        requires = [
          "docker-network-${app}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };

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
          "docker-volume-${app}-shared.service"
          "docker-${app2}.service"
          "docker-${app3}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}.service"
          "docker-volume-${app}-shared.service"
          "docker-${app2}.service"
          "docker-${app3}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
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

      "docker-volume-${app}-shared" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app}-shared || docker volume create ${app}-shared
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };

      "docker-${app4}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-volume-${app}.service"
          "docker-volume-${app}-shared.service"
          "docker-${app2}.service"
          "docker-${app3}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}.service"
          "docker-volume-${app}-shared.service"
          "docker-${app2}.service"
          "docker-${app3}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };

    };

    targets."docker-${app}-root" = {
      unitConfig = {
        Description = "root target for docker-${app} stack (dawarich, sidekiq, postgres, redis)";
      };
      wantedBy = ["multi-user.target"];
    };
  };

  services.traefik.dynamicConfigOptions.http = {
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
        servers = [
          {
            url = "http://${configVars.containerServices.${app}.containers.${app}.ipv4}:3000";
          }
        ];
      };
    };
  };

}