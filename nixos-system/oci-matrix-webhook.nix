{
  config,
  lib,
  pkgs,
  configVars,
  dockerServiceRecoveryScript,
  ...
}:

let

  app = "matrix-webhook";
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

  sops = {
    secrets = {
      bondBotPassword = {};
      matrixWebhookAdminRoom = {};
      matrixWebhookTokens = {};
    };
    templates = {
      "${app}-env".content = ''
        MATRIX_SERVER=https://matrix.${configVars.domain1}
        MATRIX_USERID=@bond-bot:${configVars.domain1}
        MATRIX_PASSWORD=${config.sops.placeholder.bondBotPassword}
        MATRIX_DEVICE=docker-webhook
        MATRIX_SSLVERIFY=True
        MATRIX_ADMIN_ROOM=${config.sops.placeholder.matrixWebhookAdminRoom}
        KNOWN_TOKENS=${config.sops.placeholder.matrixWebhookTokens}
        MESSAGE_FORMAT=json
        USE_MARKDOWN=True
        ALLOW_UNICODE=True
        DISPLAY_APP_NAME=True
        PYTHON_LOG_LEVEL=info
        LOGIN_STORE_PATH=/config
      '';
    };
  };

  virtualisation.oci-containers.containers = {

    "${app}" = {
      image = "ghcr.io/immanuelfodor/matrix-encrypted-webhooks:latest";
      autoStart = true;
      environmentFiles = [ config.sops.templates."${app}-env".path ];
      log-driver = "journald";
      volumes = [ "${app}:/config" ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.containerServices.${app}.containers.${app}.ipv4}"
        "--tty=true"
        "--stop-signal=SIGTERM"
      ];
      ports = [ "127.0.0.1:8765:8000" ];
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
          docker network inspect ${app} || docker network create --subnet ${configVars.containerServices.${app}.subnet} --driver bridge --scope local --attachable ${app}
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
