{
  pkgs,
  lib,
  config,
  configVars,
  ...
}: 

let
  app = "jellyseerr";
in

{

  virtualisation.oci-containers.containers."${app}" = {
    image = "docker.io/fallenbagel/${app}:2.0.1";
    autoStart = true;
    log-driver = "journald";
    volumes = [
      "${app}:/app/config"
    ];
    #ports = [ "5055:5055/tcp" ];
    extraOptions = [
      "--network=${app}"
      "--ip=${configVars.jellyseerrIp}"
    ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.${app}.entrypoints" = "websecure";
      "traefik.http.routers.${app}.rule" = "Host(`${app}.${configVars.domain3}`)";
      "traefik.http.routers.${app}.tls" = "true";
      "traefik.http.routers.${app}.tls.options" = "tls-13@file";
      "traefik.http.routers.${app}.middlewares" = "secure-headers@file";
      "traefik.http.services.${app}.loadbalancer.server.port" = "5055";
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
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}.service"
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
          docker network inspect ${app} || docker network create --subnet ${configVars.jellyseerrSubnet} --driver bridge --scope local --attachable ${app}
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
    };
    targets."docker-${app}-root" = {
      unitConfig = {
        Description = "root target for docker-${app}";
      };
      wantedBy = ["multi-user.target"];
    };
  }; 

}