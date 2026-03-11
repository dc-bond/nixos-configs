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
      "/var/lib/docker/volumes/${app}-storage"   # import file attachments
      "/var/lib/docker/volumes/${app}-public"    # user-generated exports
      "/var/lib/docker/volumes/${app}-watched"   # auto-import watcher directory for pending imports
      "/var/lib/docker/volumes/${app2}"          # postgres database
      "/var/lib/docker/volumes/${app}-shared"    # redis persistent data (job queues) - prevents data loss on restart
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
        STORE_GEODATA=true
        RAILS_LOG_TO_STDOUT=true
        APPLICATION_HOSTS=${app}.${configVars.domain2}
        APPLICATION_PROTOCOL=https
        DATABASE_HOST=${app2}
        DATABASE_USERNAME=${app}
        DATABASE_PASSWORD=${config.sops.placeholder.dawarichDbPasswd}
        DATABASE_NAME=${app}
        DATABASE_PORT=5432
        REDIS_URL=redis://${app3}:6379
        SECRET_KEY_BASE=${config.sops.placeholder.dawarichSecretKeyBase}
        TIME_ZONE=America/New_York
      '';
      "${app2}-env".content = ''
        POSTGRES_USER=${app}
        POSTGRES_PASSWORD=${config.sops.placeholder.dawarichDbPasswd}
        POSTGRES_DB=${app}
      '';
      "${app4}-env".content = ''
        RAILS_ENV=production
        SELF_HOSTED=true
        STORE_GEODATA=true
        RAILS_LOG_TO_STDOUT=true
        APPLICATION_HOSTS=${app}.${configVars.domain2}
        APPLICATION_PROTOCOL=https
        DATABASE_HOST=${app2}
        DATABASE_USERNAME=${app}
        DATABASE_PASSWORD=${config.sops.placeholder.dawarichDbPasswd}
        DATABASE_NAME=${app}
        DATABASE_PORT=5432
        REDIS_URL=redis://${app3}:6379
        SECRET_KEY_BASE=${config.sops.placeholder.dawarichSecretKeyBase}
        TIME_ZONE=America/New_York
        BACKGROUND_PROCESSING_CONCURRENCY=10
      '';
    };
  };

  virtualisation.oci-containers.containers = {

    "${app2}" = {
      image = "docker.io/postgis/postgis:17-3.5-alpine"; # https://hub.docker.com/r/postgis/postgis/tags
      autoStart = true;
      environmentFiles = [ config.sops.templates."${app2}-env".path ];
      log-driver = "journald";
      volumes = [
        "${app2}:/var/lib/postgresql/data"
        "${app}-shared:/var/shared"
      ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.containerServices.${app}.containers.${app2}.ipv4}"
        "--tty=true"
        "--stop-signal=SIGINT"
        "--shm-size=1g"
        "--health-cmd=pg_isready -U ${app} -d ${app}"
        "--health-interval=10s"
        "--health-timeout=10s"
        "--health-retries=5"
        "--health-start-period=30s"
      ];
    };

    "${app3}" = {
      image = "docker.io/library/redis:7.4-alpine"; # https://hub.docker.com/_/redis
      autoStart = true;
      cmd = [ "redis-server" ];
      log-driver = "journald";
      volumes = [ "${app}-shared:/data" ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.containerServices.${app}.containers.${app3}.ipv4}"
        "--tty=true"
        "--stop-signal=SIGINT"
        "--health-cmd=redis-cli --raw incr ping"
        "--health-interval=10s"
        "--health-timeout=10s"
        "--health-retries=5"
        "--health-start-period=30s"
      ];
    };

    "${app}" = {
      image = "docker.io/freikin/dawarich:1.3.2"; # https://hub.docker.com/r/freikin/dawarich
      autoStart = true;
      cmd = [ "bin/rails" "server" "-p" "3000" "-b" "::" ];
      environmentFiles = [ config.sops.templates."${app}-env".path ];
      log-driver = "journald";
      volumes = [
        "${app}-public:/var/app/public"
        "${app}-watched:/var/app/tmp/imports/watched"
        "${app}-storage:/var/app/storage"
        "${app2}:/dawarich_db_data"
      ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.containerServices.${app}.containers.${app}.ipv4}"
        "--tty=true"
        "--stop-signal=SIGINT"
        "--entrypoint=web-entrypoint.sh"
        "--health-cmd=wget -qO - http://127.0.0.1:3000/api/v1/health | grep -q '\"status\"\\s*:\\s*\"ok\"'"
        "--health-interval=10s"
        "--health-timeout=10s"
        "--health-retries=30"
        "--health-start-period=30s"
      ];
    };

    "${app4}" = {
      image = "docker.io/freikin/dawarich:1.3.2"; # https://hub.docker.com/r/freikin/dawarich
      autoStart = true;
      cmd = [ "sidekiq" ];
      environmentFiles = [ config.sops.templates."${app4}-env".path ];
      log-driver = "journald";
      volumes = [
        "${app}-public:/var/app/public"
        "${app}-watched:/var/app/tmp/imports/watched"
        "${app}-storage:/var/app/storage"
      ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.containerServices.${app}.containers.${app4}.ipv4}"
        "--tty=true"
        "--stop-signal=SIGINT"
        "--entrypoint=sidekiq-entrypoint.sh"
        "--health-cmd=pgrep -f sidekiq"
        "--health-interval=10s"
        "--health-timeout=10s"
        "--health-retries=30"
        "--health-start-period=30s"
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
          "docker-volume-${app}-shared.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app2}.service"
          "docker-volume-${app}-shared.service"
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
          "docker-volume-${app}-shared.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}-shared.service"
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
          "docker-volume-${app}-public.service"
          "docker-volume-${app}-watched.service"
          "docker-volume-${app}-storage.service"
          "docker-volume-${app2}.service"
          "docker-${app2}.service"
          "docker-${app3}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}-public.service"
          "docker-volume-${app}-watched.service"
          "docker-volume-${app}-storage.service"
          "docker-volume-${app2}.service"
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

      "docker-volume-${app}-public" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app}-public || docker volume create ${app}-public
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };

      "docker-volume-${app}-watched" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app}-watched || docker volume create ${app}-watched
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };

      "docker-volume-${app}-storage" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app}-storage || docker volume create ${app}-storage
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
          "docker-volume-${app}-public.service"
          "docker-volume-${app}-watched.service"
          "docker-volume-${app}-storage.service"
          "docker-${app2}.service"
          "docker-${app3}.service"
          "docker-${app}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}-public.service"
          "docker-volume-${app}-watched.service"
          "docker-volume-${app}-storage.service"
          "docker-${app2}.service"
          "docker-${app3}.service"
          "docker-${app}.service"
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