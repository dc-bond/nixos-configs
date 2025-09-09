{ 
  config,
  lib,
  pkgs, 
  configVars,
  ... 
}: 

let
  app = "chromium";
  app2 = "chromium-vpn";
in

{

  networking.wireguard.enable = true;
  
  sops = {
    secrets = {
      vpnPrivateKey = {};
    };
    templates = {
      "${app2}-env".content = ''
        TZ=America/New_York
        PRIVATE_KEY=${config.sops.placeholder.vpnPrivateKey}
        NET_LOCAL=192.168.1.0/24
      '';
    };
  };

  virtualisation.oci-containers.containers = {

    "${app}" = {
      image = "lscr.io/linuxserver/chromium:fdb79002-ls107"; # https://github.com/linuxserver/docker-chromium/releases
      autoStart = true;
      volumes = [ "${app}:/config" ];
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/New_York";
      };
      log-driver = "journald";
      dependsOn = ["${app2}"];
      extraOptions = [
        "--network=container:${app2}"
        "--shm-size=1g"
        "--security-opt=seccomp=unconfined"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

    "${app2}" = {
      image = "docker.io/bubuntux/nordlynx:2025-01-01"; # https://hub.docker.com/r/bubuntux/nordlynx/tags
      autoStart = true;
      log-driver = "journald";
      environmentFiles = [ config.sops.templates."${app2}-env".path ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.chromiumVpnIp}"
        "--sysctl=net.ipv6.conf.all.disable_ipv6=1"
        "--cap-add=NET_ADMIN"
        "--privileged"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${app}.entrypoints" = "websecure";
        "traefik.http.routers.${app}.rule" = "Host(`${app2}.${configVars.domain2}`)";
        "traefik.http.routers.${app}.tls" = "true";
        "traefik.http.routers.${app}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app}.middlewares" = "private-whitelist@file,secure-headers@file";
        "traefik.http.services.${app}.loadbalancer.server.port" = "3000"; # port for chromium container
      };
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
          docker network inspect ${app} || docker network create --subnet ${configVars.chromiumSubnet} --driver bridge --scope local --attachable ${app}
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
          "docker-${app2}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}.service"
          "docker-${app2}.service"
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
      
      "docker-${app2}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
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
        Description = "root target for ${app} container stack";
      };
      wantedBy = ["multi-user.target"];
    };
  }; 

}