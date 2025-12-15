{ 
  config,
  lib,
  pkgs, 
  configVars,
  dockerServiceRecoveryScript,
  ... 
}: 

let

  app = "recipesage";
  app1 = "proxy"; 
  app2 = "static";
  app3 = "api"; # volume
  app4 = "typesense"; # volume
  app5 = "pushpin"; # bind mount
  app6 = "postgres"; # volume
  app7 = "browserless"; 
  app8 = "ingredient-instruction-classifier";
  recoveryPlan = {
    restoreItems = [
      "/var/lib/docker/volumes/${app}-api"
      "/var/lib/docker/volumes/${app}-postgres"
      "/var/lib/docker/volumes/${app}-typesense"
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

  environment = {
    systemPackages = with pkgs; [ recoverScript ];
    etc."start-recipesage-pushpin.sh" = {
      text = ''
        #!/bin/sh
        sed -i "s/sig_key=changeme/sig_key=$GRIP_KEY/" /etc/pushpin/pushpin.conf
        echo "* ''${TARGET},over_http" > /etc/pushpin/routes
        exec pushpin --merge-output
      '';
      mode = "0755";
    };
  };

  backups.serviceHooks = {
    preHook = lib.mkAfter [ "systemctl stop docker-${app}-root.target" ];
    postHook = lib.mkAfter [ "systemctl start docker-${app}-root.target" ];
  };

  services.borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;
  
  sops = {
    secrets = {
      recipesageGripKey = {};
      recipesagePostgresDb = {};
      recipesagePostgresUser = {};
      recipesagePostgresPasswd = {};
      recipesageOpenaiApiKey = {};
    };
    templates = {

      "${app3}-env".content = ''
        STORAGE_TYPE=filesystem
        FILESYSTEM_STORAGE_PATH=/rs-media
        NODE_ENV=selfhost
        VERBOSE=false
        VERSION=selfhost
        POSTGRES_DB=${config.sops.placeholder.recipesagePostgresDb}
        POSTGRES_USER=${config.sops.placeholder.recipesagePostgresUser}
        POSTGRES_PASSWORD=${config.sops.placeholder.recipesagePostgresPasswd}
        POSTGRES_PORT=5432
        POSTGRES_HOST=${app6}
        POSTGRES_SSL=false
        POSTGRES_LOGGING=false
        DATABASE_URL=postgresql://${config.sops.placeholder.recipesagePostgresUser}:${config.sops.placeholder.recipesagePostgresPasswd}@${app6}:5432/${config.sops.placeholder.recipesagePostgresDb}
        GRIP_URL=http://${app5}:5561/
        GRIP_KEY=${config.sops.placeholder.recipesageGripKey}
        SEARCH_PROVIDER=${app4}
        TYPESENSE_NODES=[{"host": "${app4}", "port": 8108, "protocol": "http"}]
        TYPESENSE_API_KEY=recipesage
        BROWSERLESS_HOST=${app7}
        BROWSERLESS_PORT=3000
        INGREDIENT_INSTRUCTION_CLASSIFIER_URL=http://${app8}:3000/
        OPENAI_API_KEY=${config.sops.placeholder.recipesageOpenaiApiKey}
      '';

      "${app6}-env".content = ''
        POSTGRES_DB=${config.sops.placeholder.recipesagePostgresDb}
        POSTGRES_USER=${config.sops.placeholder.recipesagePostgresUser}
        POSTGRES_PASSWORD=${config.sops.placeholder.recipesagePostgresPasswd}
      '';

    };
  };

  # https://github.com/julianpoy/RecipeSage-selfhost
  virtualisation.oci-containers.containers = {

    "${app1}" = {
      image = "docker.io/julianpoy/recipesage-selfhost-proxy:v4.0.0";
      autoStart = true;
      log-driver = "journald";
      dependsOn = [
        "${app2}"
        "${app3}"
        "${app5}"
      ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.recipesageProxyIp}"
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
        "traefik.http.services.${app}.loadbalancer.server.port" = "80";
      };
    };

    "${app2}" = {
      image = "docker.io/julianpoy/recipesage-selfhost:static-v2.15.11";
      autoStart = true;
      log-driver = "journald";
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.recipesageStaticIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

    "${app3}" = {
      image = "docker.io/julianpoy/recipesage-selfhost:api-v2.15.11";
      autoStart = true;
      log-driver = "journald";
      dependsOn = [
        "${app4}"
        "${app5}"
        "${app6}"
        "${app7}"
      ];
      cmd = [
        "sh" 
        "-c" 
        "npx prisma migrate deploy; npx nx seed prisma; npx ts-node --swc --project packages/backend/tsconfig.json packages/backend/src/bin/www"
      ];
      environmentFiles = [ config.sops.templates."${app3}-env".path ];
      volumes = [ "${app}-${app3}:/rs-media" ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.recipesageApiIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

    "${app4}" = {
      image = "docker.io/typesense/typesense:0.24.1";
      autoStart = true;
      log-driver = "journald";
      volumes = [ "${app}-${app4}:/data" ];
      cmd = [ 
        "--data-dir" 
        "/data"
        "--api-key=recipesage"
        "--enable-cors" 
      ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.recipesageTypesenseIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

    "${app5}" = {
      image = "docker.io/julianpoy/pushpin:2023-09-17";
      autoStart = true;
      log-driver = "journald";
      cmd = [ "/start-recipesage-pushpin.sh" ];
      volumes = [ "/etc/start-recipesage-pushpin.sh:/start-recipesage-pushpin.sh" ];
      environment = { 
        GRIP_KEY = "${config.sops.placeholder.recipesageGripKey}";
        TARGET = "${app3}:3000";
      };
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.recipesagePushpinIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

    "${app6}" = {
      image = "docker.io/postgres:16";
      autoStart = true;
      log-driver = "journald";
      volumes = [ "${app}-${app6}:/var/lib/postgresql/data" ];
      environmentFiles = [ config.sops.templates."${app6}-env".path ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.recipesagePostgresIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

    "${app7}" = {
      image = "docker.io/browserless/chrome:1.61.0-puppeteer-21.4.1";
      autoStart = true;
      log-driver = "journald";
      environment = { 
        MAX_CONCURRENT_SESSIONS = "3"; 
        MAX_QUEUE_LENGTH = "10"; 
      };
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.recipesageBrowserlessIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

    "${app8}" = {
      image = "docker.io/julianpoy/ingredient-instruction-classifier:1.4.11";
      autoStart = true;
      log-driver = "journald";
      environment = { 
        SENTENCE_EMBEDDING_BATCH_SIZE = "200";
        PREDICTION_CONCURRENCY = "2";
      };
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.recipesageIngredientIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

  };

  systemd = {
    services = { 

      "docker-${app1}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-${app2}.service"
          "docker-${app3}.service"
          "docker-${app5}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-${app2}.service"
          "docker-${app3}.service"
          "docker-${app5}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
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
      
      "docker-${app3}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-volume-${app}-${app3}.service"
          "docker-${app4}.service"
          "docker-${app5}.service"
          "docker-${app6}.service"
          "docker-${app7}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}-${app3}.service"
          "docker-${app4}.service"
          "docker-${app5}.service"
          "docker-${app6}.service"
          "docker-${app7}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };

      "docker-volume-${app}-${app3}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app}-${app3} || docker volume create ${app}-${app3}
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
          "docker-volume-${app}-${app4}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}-${app4}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      
      "docker-volume-${app}-${app4}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app}-${app4} || docker volume create ${app}-${app4}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };
      
      "docker-${app5}" = {
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
      
      "docker-${app6}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-volume-${app}-${app6}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}-${app6}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      
      "docker-volume-${app}-${app6}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app}-${app6} || docker volume create ${app}-${app6}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };
      
      "docker-${app7}" = {
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
      
      "docker-${app8}" = {
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

      "docker-network-${app}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${pkgs.docker}/bin/docker network rm -f ${app}";
        };
        script = ''
          docker network inspect ${app} || docker network create --subnet ${configVars.recipesageSubnet} --driver bridge --scope local --attachable ${app}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };

    };
    targets."docker-${app}-root" = {
      unitConfig = {
        Description = "root target for ${app} container stack";
      };
      wantedBy = ["multi-user.target"];
    };
  }; 

}