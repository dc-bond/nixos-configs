{
  config,
  lib,
  pkgs,
  configVars,
  dockerServiceRecoveryScript,
  ...
}:

let

  app = "matrix-hookshot";
  app2 = "redis";
  recoveryPlan = {
    restoreItems = [
      "/var/lib/docker/volumes/${app}"
      "/var/lib/docker/volumes/${app}-${app2}"
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

  services.traefik.dynamicConfigOptions.http.middlewares.webhooks-allow.ipAllowList.sourceRange = [
    "${configVars.hosts.aspen.networking.tailscaleIp}"
  ];

  sops = {
    secrets = {
      matrixHookshotAsToken = {};
      matrixHookshotHsToken = {};
      matrixHookshotPasskey = {};
    };
    templates = {

      "${app}-config.yml".content = ''
        bridge:
          domain: ${configVars.domain1}
          url: http://host.docker.internal:8008
          mediaUrl: https://matrix.${configVars.domain1}
          port: 9993
          bindAddress: 0.0.0.0
        logging:
          level: info
          colorize: true
          json: false
          timestampFormat: HH:mm:ss:SSS
        passFile: /data/passkey.pem
        listeners:
          - port: 9000
            bindAddress: 0.0.0.0
            resources:
              - webhooks
          - port: 9001
            bindAddress: 127.0.0.1
            resources:
              - metrics
        cache:
          redisUri: redis://${app2}:6379
        encryption:
          storagePath: /data/cryptostore
        permissions:
          - actor: ${configVars.domain1}
            services:
              - service: webhooks
                level: manageConnections
        generic:
          enabled: true
          outbound: false
          urlPrefix: https://webhooks.${configVars.domain2}/
          userIdPrefix: _hookshot_
          allowJsTransformationFunctions: false
          waitForComplete: false
        bot:
          displayname: Bond-Bot 
          avatar: mxc://matrix.org/xxx
        metrics:
          enabled: true
      '';

      "${app}-registration.yml".content = ''
        id: matrix-hookshot
        url: http://${configVars.containerServices.${app}.containers.${app}.ipv4}:9993
        as_token: ${config.sops.placeholder.matrixHookshotAsToken}
        hs_token: ${config.sops.placeholder.matrixHookshotHsToken}
        sender_localpart: hookshot
        rate_limited: false
        namespaces:
          users:
            - regex: '@_hookshot_.*:${configVars.domain1}'
              exclusive: true
            - regex: '@hookshot:${configVars.domain1}'
              exclusive: true
          aliases: []
          rooms: []
      '';

      "${app}-passkey.pem".content = ''
        ${config.sops.placeholder.matrixHookshotPasskey}
      '';
      
    };
  };

  virtualisation.oci-containers.containers = {

    "${app}" = {
      image = "docker.io/halfshot/matrix-hookshot:latest"; # https://hub.docker.com/r/halfshot/matrix-hookshot/tags
      autoStart = true;
      log-driver = "journald";
      volumes = [
        "${app}:/data"
        "${config.sops.templates."${app}-config.yml".path}:/data/config.yml:ro"
        "${config.sops.templates."${app}-registration.yml".path}:/data/registration.yml:ro"
        "${config.sops.templates."${app}-passkey.pem".path}:/data/passkey.pem:ro"
      ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.containerServices.${app}.containers.${app}.ipv4}"
        "--add-host=host.docker.internal:host-gateway"
        "--tty=true"
        "--stop-signal=SIGTERM"
      ];
      labels = {
        "traefik.enable" = "true";
        # webhook endpoint (n8n/external -> hookshot)
        # note: appservice endpoint (port 9993) is not exposed via traefik; synapse connects directly to container IP for better reliability
        "traefik.http.routers.${app}-webhooks.entrypoints" = "websecure";
        "traefik.http.routers.${app}-webhooks.rule" = "Host(`webhooks.${configVars.domain2}`)";
        "traefik.http.routers.${app}-webhooks.tls" = "true";
        "traefik.http.routers.${app}-webhooks.tls.options" = "tls-13@file";
        "traefik.http.routers.${app}-webhooks.middlewares" = "webhooks-allow@file";
        "traefik.http.routers.${app}-webhooks.service" = "${app}-webhooks";
        "traefik.http.services.${app}-webhooks.loadbalancer.server.port" = "9000";
      };
    };

    "${app}-${app2}" = {
      image = "docker.io/redis:7-alpine";
      autoStart = true;
      log-driver = "journald";
      volumes = [ "${app}-${app2}:/data" ];
      cmd = [ "redis-server" "--save" "60" "1" "--loglevel" "warning" ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.containerServices.${app}.containers.${app2}.ipv4}"
      ];
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
          "docker-${app}-${app2}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}.service"
          "docker-${app}-${app2}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };

      "docker-${app}-${app2}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-volume-${app}-${app2}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}-${app2}.service"
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

      "docker-volume-${app}-${app2}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app}-${app2} || docker volume create ${app}-${app2}
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
