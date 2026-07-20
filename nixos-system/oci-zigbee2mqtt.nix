{
  config,
  lib,
  pkgs,
  configVars,
  dockerServiceRecoveryScript,
  ...
}:

# Requires:
#   - services.mosquitto (already provided by home-assistant.nix)
#   - an SMLIGHT SLZB-06 POE Zigbee coordinator on the LAN, running SLZB-OS in
#     "Zigbee2MQTT (TCP)" mode, reachable at configVars.devices.slzb06.ipv4:6638
#   - sops secret `mqttZ2mPasswd` — used both to seed a mosquitto user
#     (see home-assistant.nix mosquitto listeners) and to auth Z2M to the broker

let
  app = "zigbee2mqtt";
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

  sops = {
    secrets = {
      mqttZ2mPasswd = { };
    };
    templates = {
      "${app}-env".content = ''
        TZ=America/New_York
        ZIGBEE2MQTT_CONFIG_MQTT_SERVER=mqtt://${configVars.hosts.aspen.networking.ipv4}:1883
        ZIGBEE2MQTT_CONFIG_MQTT_USER=zigbee2mqtt
        ZIGBEE2MQTT_CONFIG_MQTT_PASSWORD=${config.sops.placeholder.mqttZ2mPasswd}
        ZIGBEE2MQTT_CONFIG_SERIAL_PORT=tcp://${configVars.devices.slzb06.ipv4}:6638
        ZIGBEE2MQTT_CONFIG_SERIAL_ADAPTER=zstack
        ZIGBEE2MQTT_CONFIG_FRONTEND_ENABLED=true
        ZIGBEE2MQTT_CONFIG_FRONTEND_PORT=8080
        ZIGBEE2MQTT_CONFIG_HOMEASSISTANT_ENABLED=true
        ZIGBEE2MQTT_CONFIG_ADVANCED_LOG_LEVEL=info
      '';
    };
  };

  environment.systemPackages = with pkgs; [ recoverScript ];

  backups.serviceHooks = {
    preHook = lib.mkAfter [ "systemctl stop docker-${app}-root.target" ];
    postHook = lib.mkAfter [ "systemctl start docker-${app}-root.target" ];
  };

  services.borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;

  virtualisation.oci-containers.containers."${app}" = {
    image = "docker.io/koenkk/${app}:2.12.1"; # https://hub.docker.com/r/koenkk/zigbee2mqtt/tags
    autoStart = true;
    environmentFiles = [ config.sops.templates."${app}-env".path ];
    log-driver = "journald";
    volumes = [ "${app}:/app/data" ];
    extraOptions = [
      "--network=${app}"
      "--ip=${configVars.ociServices.${app}.containers.${app}.ipv4}"
      "--tty=true"
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
          "mosquitto.service"
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
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${pkgs.docker}/bin/docker network rm -f ${app}";
        };
        script = ''
          docker network inspect ${app} || docker network create --subnet ${configVars.ociServices.${app}.subnet} --driver bridge --scope local --attachable ${app}
        '';
        partOf = [ "docker-${app}-root.target" ];
        wantedBy = [ "docker-${app}-root.target" ];
      };
      "docker-volume-${app}" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app} || docker volume create ${app}
        '';
        partOf = [ "docker-${app}-root.target" ];
        wantedBy = [ "docker-${app}-root.target" ];
      };
    };
    targets."docker-${app}-root" = {
      unitConfig = {
        Description = "root target for docker-${app}";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.${app} = {
      entrypoints = [ "websecure" ];
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
            url = "http://${configVars.ociServices.${app}.containers.${app}.ipv4}:8080";
          }
        ];
      };
    };
  };

}
