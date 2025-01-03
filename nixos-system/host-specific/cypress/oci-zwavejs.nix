{ 
  config,
  lib,
  pkgs, 
  configVars,
  ... 
}: 

let
  app = "zwavejs";
in

{
  sops.secrets.zwavejsSessionSecret = {};

  virtualisation.oci-containers.containers."${app}" = {
    image = "docker.io/${app}/zwave-js-ui:9.28.0"; # https://hub.docker.com/r/zwavejs/zwave-js-ui/tags
    autoStart = true;
    #environmentFiles = [  ];
    environment = {
      TZ = "America/New_York";
      SESSION_SECRET = "${config.sops.secrets.zwavejsSessionSecret.path}";
      ZWAVEJS_EXTERNAL_CONFIG = "/usr/src/app/store/.config-db";
    };
    log-driver = "journald";
    ports = [ 
      #"8091:8091/tcp" # for browser interface
      "3000:3000/tcp" # for websocket server # docker daemon automatically opens firewall port
    ];
    volumes = [ "${app}:/usr/src/app/store" ];
    extraOptions = [
      "--network=${app}"
      "--ip=${configVars.zwaveJsIp}"
      "--tty=true"
      "--stop-signal=SIGINT"
      "--device=/dev/serial/by-id/usb-Silicon_Labs_CP2102N_USB_to_UART_Bridge_Controller_d677b47b5594eb11ba3436703d98b6d1-if00-port0:/dev/zwave"
    ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.${app}.entrypoints" = "websecure";
      "traefik.http.routers.${app}.rule" = "Host(`${app}.${configVars.domain2}`)";
      "traefik.http.routers.${app}.tls" = "true";
      "traefik.http.routers.${app}.tls.options" = "tls-13@file";
      "traefik.http.routers.${app}.middlewares" = "secure-headers@file";
      "traefik.http.services.${app}.loadbalancer.server.port" = "8091"; # port for browser interface
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
          docker network inspect ${app} || docker network create --subnet ${configVars.zwaveJsSubnet} --driver bridge --scope local --attachable ${app}
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