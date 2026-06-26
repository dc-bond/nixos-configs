{
  config,
  lib,
  pkgs,
  configVars,
  dockerServiceRecoveryScript,
  ...
}:

let
  app = "metube";
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
    image = "ghcr.io/alexta69/${app}:2026-06-20"; # https://github.com/alexta69/metube/releases
    autoStart = true;
    log-driver = "journald";
    environment = {
      UID = "1000"; # chris — matches host ownership of yt-downloads dir
      GID = "100";  # users
    };
    volumes = [
      "${app}:/downloads/.metube" # state (queue/history) — backed up via docker volume
      "${config.bulkStorage.path}/media/yt-downloads:/downloads:rw" # bind mount for downloaded videos (jellyfin reads RO via separate mount)
    ];
    extraOptions = [
      "--network=${app}"
      "--ip=${configVars.ociServices.${app}.containers.${app}.ipv4}"
      "--tty=true"
      "--stop-signal=SIGINT"
    ];
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
          docker network inspect ${app} || docker network create --subnet ${configVars.ociServices.${app}.subnet} --driver bridge --scope local --attachable ${app}
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

  services.traefik.dynamicConfigOptions.http = {
    routers.${app} = {
      entrypoints = ["websecure"];
      rule = "Host(`${app}.${configVars.domain2}`)";
      service = "${app}";
      middlewares = [
        "maintenance-page"
        "trusted-allow"
        "secure-headers"
        "forbidden-page"
      ];
      tls = {
        certResolver = "cloudflareDns";
        options = "tls-13@file";
      };
    };
    services.${app} = {
      loadBalancer = {
        serversTransport = "default";
        servers = [
          {
            url = "http://${configVars.ociServices.${app}.containers.${app}.ipv4}:8081";
          }
        ];
      };
    };
  };

}
