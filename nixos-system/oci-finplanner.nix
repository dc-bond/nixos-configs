{
  config,
  lib,
  pkgs,
  configVars,
  ...
}:

let
  app = "finplanner";
  appPort = 8501;
  gitRepo = "https://github.com/dc-bond/finplanner";
  repoDir = "/var/lib/${app}";
in

{

  virtualisation.oci-containers.containers."${app}" = {
    image = "localhost/${app}:latest";
    autoStart = true;
    log-driver = "journald";
    extraOptions = [
      "--network=${app}"
      "--ip=${configVars.${app}Ip}"
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
      "traefik.http.services.${app}.loadbalancer.server.port" = toString appPort;
    };
  };

  systemd = {
    services = {
      "docker-clone-${app}" = {
        description = "clone ${app} repository";
        path = [pkgs.git pkgs.coreutils];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.bash}/bin/bash -c 'if [ ! -d ${repoDir} ]; then ${pkgs.git}/bin/git clone ${gitRepo} ${repoDir}; else cd ${repoDir} && ${pkgs.git}/bin/git pull; fi'";
        };
        before = ["docker-build-${app}.service"];
      };

      "docker-build-${app}" = {
        description = "build ${app} docker image";
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.docker}/bin/docker build -t ${app}:latest ${repoDir}";
          ExecStartPost = "${pkgs.bash}/bin/bash -c 'rm -rf ${repoDir}'";
        };
        after = ["docker-clone-${app}.service"];
        requires = ["docker-clone-${app}.service"];
        before = ["docker-${app}.service"];
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
          docker network inspect ${app} || docker network create --subnet ${configVars.${app}Subnet} --driver bridge --scope local --attachable ${app}
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