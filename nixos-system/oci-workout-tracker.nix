{
  config,
  lib,
  pkgs,
  configVars,
  ...
}:

let
  app = "workout-tracker";
  appPort = 8502;
  gitRepo = "/var/lib/nextcloud/data/Chris Bond/files/Personal/misc/${app}";
  repoDir = "/var/lib/${app}";
in

{

  virtualisation.oci-containers.containers."${app}" = {
    image = "${app}:latest";
    autoStart = true;
    log-driver = "journald";
    extraOptions = [
      "--network=${app}"
      "--ip=${configVars.workoutTrackerIp}"
      "--tty=true"
      "--stop-signal=SIGINT"
    ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.${app}.entrypoints" = "websecure";
      "traefik.http.routers.${app}.rule" = "Host(`${app}.${configVars.domain2}`)";
      "traefik.http.routers.${app}.tls" = "true";
      "traefik.http.routers.${app}.tls.options" = "tls-13@file";
      "traefik.http.routers.${app}.middlewares" = "authelia-dcbond@file,secure-headers@file";
      "traefik.http.services.${app}.loadbalancer.server.port" = "${toString appPort}";
    };
  };

  systemd = {
    services = {
      "docker-clone-${app}" = {
        description = "clone ${app} repository";
        path = [pkgs.git pkgs.coreutils pkgs.bash];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          if [ ! -d ${repoDir} ]; then
            ${pkgs.git}/bin/git clone ${gitRepo} ${repoDir}
          else
            cd ${repoDir} && ${pkgs.git}/bin/git pull
          fi
        '';
        wantedBy = ["docker-${app}-root.target"]; 
        partOf = ["docker-${app}-root.target"]; 
      };
      
      "docker-build-${app}" = {
        description = "build ${app} docker image";
        path = [pkgs.docker pkgs.bash];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -e
          docker build -t ${app}:latest ${repoDir}
          rm -rf ${repoDir}
        '';
        after = ["docker-clone-${app}.service" "docker.service"];
        requires = ["docker-clone-${app}.service" "docker.service"];
        wantedBy = ["docker-${app}-root.target"];
        partOf = ["docker-${app}-root.target"];
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
          "docker-build-${app}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-build-${app}.service"
        ];
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
          docker network inspect ${app} || docker network create --subnet ${configVars.workoutTrackerSubnet} --driver bridge --scope local --attachable ${app}
        '';
        after = ["docker.service"];
        requires = ["docker.service"];
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