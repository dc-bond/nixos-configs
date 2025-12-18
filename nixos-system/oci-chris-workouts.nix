{
  config,
  lib,
  pkgs,
  configVars,
  dockerServiceRecoveryScript,
  ...
}:

let
  app = "chris-workouts";
  appPort = 8502;
  gitRepo = "/var/lib/nextcloud/data/Chris Bond/files/Personal/misc/${app}";
  repoDir = "/var/lib/${app}";
  recoveryPlan = {
    restoreItems = [
      "/var/lib/docker/volumes/${app}"
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

  virtualisation.oci-containers.containers."${app}" = {
    image = "${app}:latest";
    autoStart = true;
    log-driver = "journald";
    volumes = [ "${app}:/app/data" ];
    extraOptions = [
      "--network=${app}"
      "--ip=${configVars.containerServices.${app}.containers.${app}.ipv4}"
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
      "traefik.http.services.${app}.loadbalancer.server.port" = "${toString appPort}";
    };
  };

  systemd = {
    services = {

      "docker-copy-${app}" = {
        description = "copy ${app} repository";
        path = [pkgs.rsync pkgs.coreutils pkgs.bash];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          mkdir -p "${repoDir}"
          ${pkgs.rsync}/bin/rsync -av --delete "${gitRepo}/" "${repoDir}/"
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
          if ! docker image inspect ${app}:latest >/dev/null 2>&1; then
            docker build -t ${app}:latest ${repoDir}
          fi
          rm -rf ${repoDir}
        '';
        after = ["docker-copy-${app}.service" "docker.service"];
        requires = ["docker-copy-${app}.service" "docker.service"];
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

      "docker-volume-${app}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app} || docker volume create ${app}
        '';
        after = ["docker.service"];
        requires = ["docker.service"];
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
          docker network inspect ${app} || docker network create --subnet ${configVars.containerServices.${app}.subnet} --driver bridge --scope local --attachable ${app}
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