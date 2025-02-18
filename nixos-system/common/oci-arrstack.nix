{ 
  config,
  lib,
  pkgs, 
  configVars,
  ... 
}: 

let
  app = "arrstack";
  app1 = "arr-vpn";
  app2 = "sabnzbd";
  app3 = "sonarr";
  app4 = "radarr";
  app5 = "prowlarr";
in

{

  networking.wireguard.enable = true;
  
  sops = {
    secrets = {
      vpnPrivateKey = {};
    };
    templates = {
      "${app1}-env".content = ''
        TZ=America/New_York
        PRIVATE_KEY=${config.sops.placeholder.vpnPrivateKey}
        NET_LOCAL=192.168.1.0/24
      '';
    };
  };

  virtualisation.oci-containers.containers = {

    "${app1}" = {
      image = "docker.io/bubuntux/nordlynx:2025-01-01"; # https://hub.docker.com/r/bubuntux/nordlynx/tags
      autoStart = true;
      log-driver = "journald";
      environmentFiles = [ config.sops.templates."${app1}-env".path ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.arrVpnIp}"
        "--sysctl=net.ipv6.conf.all.disable_ipv6=1"
        "--cap-add=NET_ADMIN"
        "--privileged"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
      #labels = {
      #  "traefik.enable" = "true";
      #  "traefik.http.routers.${app2}.entrypoints" = "websecure";
      #  "traefik.http.routers.${app2}.rule" = "Host(`${app1}.${configVars.domain2}`)";
      #  "traefik.http.routers.${app2}.tls" = "true";
      #  "traefik.http.routers.${app2}.tls.options" = "tls-13@file";
      #  "traefik.http.routers.${app2}.middlewares" = "secure-headers@file";
      #  "traefik.http.services.${app2}.loadbalancer.server.port" = "8080"; # sabnzbd
      #  "traefik.http.routers.${app3}.entrypoints" = "websecure";
      #  "traefik.http.routers.${app3}.rule" = "Host(`${app2}.${configVars.domain2}`)";
      #  "traefik.http.routers.${app3}.tls" = "true";
      #  "traefik.http.routers.${app3}.tls.options" = "tls-13@file";
      #  "traefik.http.routers.${app3}.middlewares" = "secure-headers@file";
      #  "traefik.http.services.${app3}.loadbalancer.server.port" = "8989"; # sonarr
      #  "traefik.http.routers.${app4}.entrypoints" = "websecure";
      #  "traefik.http.routers.${app4}.rule" = "Host(`${app3}.${configVars.domain2}`)";
      #  "traefik.http.routers.${app4}.tls" = "true";
      #  "traefik.http.routers.${app4}.tls.options" = "tls-13@file";
      #  "traefik.http.routers.${app4}.middlewares" = "secure-headers@file";
      #  "traefik.http.services.${app4}.loadbalancer.server.port" = "7878"; # radarr
      #  "traefik.http.routers.${app5}.entrypoints" = "websecure";
      #  "traefik.http.routers.${app5}.rule" = "Host(`${app4}.${configVars.domain2}`)";
      #  "traefik.http.routers.${app5}.tls" = "true";
      #  "traefik.http.routers.${app5}.tls.options" = "tls-13@file";
      #  "traefik.http.routers.${app5}.middlewares" = "secure-headers@file";
      #  "traefik.http.services.${app5}.loadbalancer.server.port" = "9696"; # prowlarr
      #};
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
          docker network inspect ${app} || docker network create --subnet ${configVars.arrStackSubnet} --driver bridge --scope local --attachable ${app}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
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



      #"docker-volume-${app}" = {
      #  path = [pkgs.docker];
      #  serviceConfig = {
      #    Type = "oneshot";
      #    RemainAfterExit = true;
      #  };
      #  script = ''
      #    docker volume inspect ${app} || docker volume create ${app}
      #  '';
      #  partOf = ["docker-${app}-root.target"];
      #  wantedBy = ["docker-${app}-root.target"];
      #};
      

    };
    targets."docker-${app}-root" = {
      unitConfig = {
        Description = "root target for ${app} containers";
      };
      wantedBy = ["multi-user.target"];
    };
  }; 

}