#To migrate Unifi Controller to new host
#
#turn off old
#dns for web ui
#restore new
#update override inform host in new

{ 
  lib,
  config, 
  pkgs, 
  configVars,
  dockerServiceRecoveryScript,
  ... 
}: 

let

  app = "unifi";
  app1 = "${app}-mongodb";
  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";
  recoveryPlan = {
    serviceName = "${app}";
    localRestoreRepoPath = "${config.backups.borgDir}/${config.networking.hostName}";
    cloudRestoreRepoPath = "${config.backups.borgCloudDir}/${config.networking.hostName}";
    restoreItems = [
      "/var/lib/docker/volumes/${app}"
      "/var/lib/docker/volumes/${app1}-db"
      "/var/lib/docker/volumes/${app1}-configdb"
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
    etc."${app1}-init.sh" = {
      text = ''
        #!/bin/bash
        if which mongosh > /dev/null 2>&1; then
          mongo_init_bin='mongosh'
        else
          mongo_init_bin='mongo'
        fi
        "''${mongo_init_bin}" <<EOF
        use ''${MONGO_AUTHSOURCE}
        db.auth("''${MONGO_INITDB_ROOT_USERNAME}", "''${MONGO_INITDB_ROOT_PASSWORD}")
        db.createUser({
          user: "''${MONGO_USER}",
          pwd: "''${MONGO_PASS}",
          roles: [
            { db: "''${MONGO_DBNAME}", role: "dbOwner" },
            { db: "''${MONGO_DBNAME}_stat", role: "dbOwner" }
          ]
        })
        EOF
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
      unifiMongoRootUser = {};
      unifiMongoRootPasswd = {};
      unifiMongoUser = {};
      unifiMongoPasswd = {};
      unifiMongoDb = {};
    };
    templates = {
      "${app}-env".content = ''
        PUID=0
        PGID=0
        TZ=America/New_York
        MONGO_USER=${config.sops.placeholder.unifiMongoUser}
        MONGO_PASS=${config.sops.placeholder.unifiMongoPasswd}
        MONGO_DBNAME=${config.sops.placeholder.unifiMongoDb}
        MONGO_HOST=${app1}
        MONGO_PORT=27017
        MEM_LIMIT=1024
        MEM_STARTUP=1024
        MONGO_AUTHSOURCE=admin
      '';
      "${app1}-env".content = ''
        MONGO_INITDB_ROOT_USERNAME=${config.sops.placeholder.unifiMongoRootUser}
        MONGO_INITDB_ROOT_PASSWORD=${config.sops.placeholder.unifiMongoRootPasswd}
        MONGO_USER=${config.sops.placeholder.unifiMongoUser}
        MONGO_PASS=${config.sops.placeholder.unifiMongoPasswd}
        MONGO_DBNAME=${config.sops.placeholder.unifiMongoDb}
        MONGO_AUTHSOURCE=admin
      '';
    };
  };

  virtualisation.oci-containers.containers = {
    "${app}" = {
      image = "lscr.io/linuxserver/unifi-network-application:9.0.114-ls77"; # https://github.com/linuxserver/docker-unifi-network-application/releases 
      #image = "lscr.io/linuxserver/unifi-network-application:9.4.19-ls103"; # https://github.com/linuxserver/docker-unifi-network-application/releases 
      autoStart = true;
      log-driver = "journald";
      volumes = [ "${app}:/config" ];
      environmentFiles = [ config.sops.templates."${app}-env".path ];
      ports = [ 
        #"3478:3478/udp" # STUN port
        #"1900:1900/udp" # required for 'make controller discoverable on L2 network' option
        #"5514:5514/udp" # remote syslog port
        "10001:10001/udp" # AP discovery port
        "8080:8080" # device communication port
        #"8443:8443" # web admin port, add if not using traefik
        "8843:8843" # guest portal https redirect port
        "8880:8880" # guest portal http redirect port
        "6789:6789" # mobile throughput test
      ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.unifiControllerIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${app}.service" = "${app}";
        "traefik.http.routers.${app}.entrypoints" = "websecure";
        "traefik.http.routers.${app}.rule" = "Host(`${app}.${configVars.domain2}`)";
        "traefik.http.routers.${app}.tls" = "true";
        "traefik.http.routers.${app}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app}.middlewares" = "trusted-allow@file,secure-headers@file,unifi-headers@file";
        "traefik.http.services.${app}.loadbalancer.server.port" = "8443";
        "traefik.http.services.${app}.loadbalancer.server.scheme" = "https"; # drop if not using traefik
      };
    };
    "${app1}" = {
      image = "docker.io/mongo:7.0"; # https://hub.docker.com/_/mongo/tags
      autoStart = true;
      log-driver = "journald";
      environmentFiles = [ config.sops.templates."${app1}-env".path ];
      volumes = [ 
        "${app1}-db:/data/db"
        "${app1}-configdb:/data/configdb"
        "/etc/${app1}-init.sh:/docker-entrypoint-initdb.d/init-mongo.sh:ro"
      ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.unifiMongoIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

  };
  
  services.traefik = {
    staticConfigOptions.serversTransport.insecureSkipVerify = true; 
    dynamicConfigOptions.http.middlewares.unifi-headers.headers.customRequestHeaders.Authorization = "";
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
          docker network inspect ${app} || docker network create --subnet ${configVars.unifiSubnet} --driver bridge --scope local --attachable ${app}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
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
          "docker-${app1}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}.service"
          "docker-${app1}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      "docker-${app1}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-volume-${app1}-db.service"
          "docker-volume-${app1}-configdb.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app1}-db.service"
          "docker-volume-${app1}-configdb.service"
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
      "docker-volume-${app1}-db" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app1}-db || docker volume create ${app1}-db
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };
      "docker-volume-${app1}-configdb" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app1}-configdb || docker volume create ${app1}-configdb
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };
    };
    targets."docker-${app}-root" = {
      unitConfig = {
        Description = "root target for docker-${app}";
      };
      wantedBy = ["multi-user.target"];
    };
  }; 

}