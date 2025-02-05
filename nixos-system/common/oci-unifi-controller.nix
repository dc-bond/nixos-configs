{ 
  lib,
  config, 
  pkgs, 
  configVars,
  ... 
}: 

let
  app = "unifi-controller";
  app1 = "${app}-mongodb";
in

{
  
  sops = {
    secrets = {
      unifiMongoUser = {};
      unifiMongoPasswd = {};
      unifiMongoDb = {};
    };
    templates = {
      "${app}-env".content = ''
        PUID=1000
        PGID=1000
        TZ=America/New_York
        MONGO_USER=${config.sops.placeholder.unifiMongoUser}
        MONGO_PASS=${config.sops.placeholder.unifiMongoPasswd}
        MONGO_DBNAME=${config.sops.placeholder.unifiMongoDb}
        MONGO_HOST=${app1}
        MONGO_PORT=27017 # mongodb port only evaluated on first run
        MEM_LIMIT=1024
        MEM_STARTUP=1024 #optional
      '';
      "${app1}-env".content = ''
        MONGO_INITDB_ROOT_USERNAME=${config.sops.placeholder.unifiMongoUser}
        MONGO_INITDB_ROOT_PASSWORD=${config.sops.placeholder.unifiMongoPasswd}
        MONGO_INITDB_DATABASE=${config.sops.placeholder.unifiMongoDb}
      '';
    };
  };

  virtualisation.oci-containers.containers = {
    "${app}" = {
      image = "lscr.io/linuxserver/unifi-network-application:9.0.114-ls77"; # https://github.com/linuxserver/docker-unifi-network-application/releases 
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
        "8443:8443" # web admin port
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
      #labels = {
      #  "traefik.enable" = "true";
      #  "traefik.http.routers.${app}.service" = "${app}";
      #  "traefik.http.routers.${app}.entrypoints" = "websecure";
      #  "traefik.http.routers.${app}.rule" = "Host(`${app}.${configVars.domain2}`)";
      #  "traefik.http.routers.${app}.tls" = "true";
      #  "traefik.http.routers.${app}.tls.options" = "tls-13@file";
      #  "traefik.http.routers.${app}.middlewares" = "secure-headers@file";
      #  "traefik.http.services.${app}.loadbalancer.server.port" = "8443";
      #};
    };
    "${app1}" = {
      image = "docker.io/mongo:8.0.4"; # https://hub.docker.com/_/mongo/tags
      autoStart = true;
      log-driver = "journald";
      environmentFiles = [ config.sops.templates."${app1}-env".path ];
      volumes = [ "${app1}:/data" ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.unifiMongoIp}"
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
          "docker-volume-${app1}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app1}.service"
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
      "docker-volume-${app1}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app1} || docker volume create ${app1}
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