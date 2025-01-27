{ 
  config,
  lib,
  pkgs, 
  configVars,
  ... 
}: 

let
  app = "recipesage";
  app1 = "recipesage-nginx";
  app2 = "recipesage-static";
  app3 = "recipesage-api";
  app4 = "recipesage-elasticsearch"; # volume
  app5 = "recipesage-pushpin";
  app6 = "recipesage-postgres"; # volume
  app7 = "recipesage-browserless";
  app8 = "recipesage-ingredient-instruction-classifier";
  app9 = "recipesage-minio"; # volume
in

{
  
  sops = {
    secrets = {
      recipesageApiAwsAccessKeyId = {};
      recipesageApiAwsSecretAccessKey = {};
      recipesagePostgresDb = {};
      recipesagePostgresUser = {};
      recipesagePostgresPasswd = {};
      recipesageElasticPasswd = {};
      recipesageMinioRootUser = {};
      recipesageMinioRootPasswd = {};
    };
    templates = {

      "${app3}-env".content = ''
        AWS_ACCESS_KEY_ID=${config.sops.placeholder.recipesageApiAwsAccessKeyId}
        AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.recipesageApiAwsSecretAccessKey}
        AWS_REGION=us-west-2
        AWS_BUCKET=recipesage-selfhost
        AWS_ENDPOINT=http://${app9}:9000/
        AWS_S3_PUBLIC_PATH=/myminio/recipesage-selfhost/
        AWS_S3_FORCE_PATH_STYLE=true
        AWS_S3_SIGNATURE_VERSION=v4
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
        GCM_KEYPAIR
        SENTRY_DSN
        GRAYLOG_HOST=localhost
        GRAYLOG_PORT
        GRIP_URL=http://${app5}:5561/
        GRIP_KEY=recipesage
        ELASTIC_ENABLE=true
        ELASTIC_IDX_PREFIX=rs_selfhost_
        ELASTIC_CONN=http://elastic:recipesage_selfhost@${app4}:9200
        ELASTIC_PASSWORD=recipesage_selfhost
        STRIPE_SK
        STRIPE_WEBHOOK_SECRET
        BROWSERLESS_HOST=${app7}
        BROWSERLESS_PORT=3000
        INGREDIENT_INSTRUCTION_CLASSIFIER_URL=http://${app8}:3000/
      '';

      "${app4}-env".content = ''
        discovery.type=single-node
        xpack.security.enabled=false
        ELASTIC_PASSWORD=${config.sops.placeholder.recipesageElasticPasswd}
        ES_JAVA_OPTS=-Xms1024m -Xmx1024m 
      '';

      "${app6}-env".content = ''
        POSTGRES_DB=${config.sops.placeholder.recipesagePostgresDb}
        POSTGRES_USER=${config.sops.placeholder.recipesagePostgresUser}
        POSTGRES_PASSWORD=${config.sops.placeholder.recipesagePostgresPasswd}
      '';

      "${app9}-env".content = ''
        MINIO_ROOT_USER=${config.sops.placeholder.recipesageMinioRootUser}
        MINIO_ROOT_PASSWORD=${config.sops.placeholder.recipesageMinioRootPasswd}
      '';
      
    };
  };

  #environment.etc = {
  #  "recipesage-nginx-default.conf" = {
  #    user = "docker";
  #    group = "docker";      
  #    text = ''
  #      server {
  #        client_max_body_size 1G;
  #      	listen 80;
  #      	server_name localhost;
  #        location /grip/ws {
  #          resolver 127.0.0.11 valid=30s;
  #          proxy_http_version 1.1;
  #          proxy_set_header Upgrade $http_upgrade;
  #          proxy_set_header Connection "Upgrade";
  #          proxy_connect_timeout 1h;
  #          proxy_send_timeout 1h;
  #          proxy_read_timeout 1h;
  #          proxy_pass http://recipesage-pushpin:7999/ws;
  #        }
  #        location /myminio/ {
  #          resolver 127.0.0.11 valid=30s;
  #          proxy_pass http://recipesage-minio:9000/;
  #        }
  #        location /api/ {
  #          resolver 127.0.0.11 valid=30s;
  #          proxy_pass http://recipesage-api:3000/;
  #        }
  #      	location / {
  #          resolver 127.0.0.11 valid=30s;
  #          proxy_pass http://recipesage-static:80/;
  #      	}
  #      }
  #    '';
  #  };
  #  #"recipesage-static.entrypoint.sh".text = ''
  #  #  #!/bin/sh
  #  #  sed -i 's|<base href="\/">.*|<base href="/"><script>window.API_BASE_OVERRIDE = '${API_BASE_OVERRIDE}';</script>|i' /usr/share/nginx/html/index.html
  #  #'';
  #};


  virtualisation.oci-containers.containers = {

    "${app1}" = {
      image = "docker.io/nginx:1.27.3"; # https://hub.docker.com/_/nginx/tags
      autoStart = true;
      log-driver = "journald";
      volumes = [ 
        "/home/chris/proxy.conf:/etc/nginx/conf.d/default.conf" 
      ];
      dependsOn = [
        "${app2}"
        "${app3}"
        "${app5}"
      ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.recipesageNginxIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${app}.entrypoints" = "websecure";
        "traefik.http.routers.${app}.rule" = "Host(`${app}.${configVars.domain2}`)";
        "traefik.http.routers.${app}.tls" = "true";
        "traefik.http.routers.${app}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app}.middlewares" = "secure-headers@file";
        "traefik.http.services.${app}.loadbalancer.server.port" = "80";
      };
    };

    "${app2}" = {
      image = "docker.io/julianpoy/recipesage-selfhost:static-v2.9.9";
      autoStart = true;
      log-driver = "journald";
      volumes = [ 
        "/home/chris/static.entrypoint.sh:/docker-entrypoint.d/static.entrypoint.sh" 
      ];
      environment = {
        DISABLE_REGISTRATION = "true";
        API_BASE_OVERRIDE = "null";
      };
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.recipesageStaticIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

    "${app3}" = {
      image = "docker.io/julianpoy/recipesage-selfhost:api-v2.9.9";
      autoStart = true;
      log-driver = "journald";
      cmd = [ "/app/www" ];
      environmentFiles = [ config.sops.templates."${app3}-env".path ];
      dependsOn = [
        "${app4}"
        "${app5}"
        "${app6}"
        "${app7}"
      ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.recipesageApiIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${app}.entrypoints" = "websecure";
        "traefik.http.routers.${app}.rule" = "Host(`${app}.${configVars.domain2}`)";
        "traefik.http.routers.${app}.tls" = "true";
        "traefik.http.routers.${app}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app}.middlewares" = "secure-headers@file";
        "traefik.http.services.${app}.loadbalancer.server.port" = "80";
      };
    };

    "${app4}" = {
      image = "docker.elastic.co/elasticsearch/elasticsearch:8.5.3";
      autoStart = true;
      log-driver = "journald";
      volumes = [ 
        "${app4}:/usr/share/elasticsearch/data" 
      ];
      environmentFiles = [ config.sops.templates."${app4}-env".path ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.recipesageElasticsearchIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

    "${app5}" = {
      image = "docker.io/fanout/pushpin:1.27.0";
      autoStart = true;
      log-driver = "journald";
      environment = { 
        target = "${app3}:3000";
      };
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.recipesagePushpinIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

    "${app6}" = {
      image = "docker.io/postgres:15.1";
      autoStart = true;
      log-driver = "journald";
      volumes = [ 
        "${app6}:/var/lib/postgresql/data" 
      ];
      environmentFiles = [ config.sops.templates."${app6}-env".path ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.recipesagePostgresIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

    "${app7}" = {
      image = "docker.io/browserless/chrome:1.53.0-chrome-stable";
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
        PREDICTION_CONCURRENCY = "4";
      };
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.recipesageIngredientIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

    "${app9}" = {
      image = "docker.io/minio/minio:RELEASE.2025-01-20T14-49-07Z"; # https://hub.docker.com/r/minio/minio/tags
      autoStart = true;
      log-driver = "journald";
      volumes = [ 
        "${app9}:/data" 
      ];
      cmd = [ "server /data" ];
      environmentFiles = [ config.sops.templates."${app9}-env".path ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.recipesageMinioIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${app9}.entrypoints" = "websecure";
        "traefik.http.routers.${app9}.rule" = "Host(`${app9}.${configVars.domain2}`)";
        "traefik.http.routers.${app9}.tls" = "true";
        "traefik.http.routers.${app9}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app9}.middlewares" = "secure-headers@file";
        "traefik.http.services.${app9}.loadbalancer.server.port" = "9000";
      };
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
      
      "docker-${app4}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-volume-${app4}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app4}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      
      "docker-volume-${app4}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app4} || docker volume create ${app4}
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
          "docker-volume-${app6}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app6}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      
      "docker-volume-${app6}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app6} || docker volume create ${app6}
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

      "docker-${app9}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-volume-${app9}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app9}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };

      "docker-volume-${app9}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app9} || docker volume create ${app9}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
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