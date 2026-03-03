{ 
  config,
  lib,
  pkgs, 
  configVars,
  ... 
}: 

let
  app = "fava";
in

{

  virtualisation.oci-containers.containers."${app}" = {
    image = "docker.io/yegle/${app}:v1.27"; # https://hub.docker.com/r/yegle/fava/tags
    autoStart = true;
    log-driver = "journald";
    volumes = [ "/var/lib/nextcloud/data/Chris Bond/files/Bond Family/Financial/bond-ledger:/bean" ];
    environment = { 
      BEANCOUNT_FILE = "/bean/master.beancount";
    };
    extraOptions = [
      "--network=${app}"
      "--ip=${configVars.containerServices.${app}.containers.${app}.ipv4}"
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
      rule = "Host(`bond-ledger.${configVars.domain2}`)";
      service = "${app}";
      middlewares = [
        "maintenance-page"
        "forbidden-page"
        "trusted-allow"
        "secure-headers"
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
            url = "http://${configVars.containerServices.${app}.containers.${app}.ipv4}:5000";
          }
        ];
      };
    };
  };

}