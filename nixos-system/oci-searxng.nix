{ 
  lib,
  config, 
  pkgs, 
  configVars,
  ... 
}: 

let
  app = "searxng";
in

{

  environment = {
    etc."searxng/settings.yml" = {
      text = ''
        use_default_settings: true
        server:
          secret_key: "searxng-testing12345"
        search:
          formats:
            - html
            - json
      '';
      mode = "0644";
    };
  };
  
  virtualisation.oci-containers.containers."${app}" = {
    image = "docker.io/${app}/${app}:2025.8.1-3d96414"; # https://hub.docker.com/r/searxng/searxng/tags
    autoStart = true;
    log-driver = "journald";
    volumes = [ "/etc/searxng/settings.yml:/etc/searxng/settings.yml:ro" ];
    environment = { SEARXNG_BASE_URL = "https://search.${configVars.domain2}"; };
    extraOptions = [
      "--tmpfs=/etc/searxng"
      "--tmpfs=/var/cache/searxng" 
      "--network=${app}"
      "--ip=${configVars.containerServices.${app}.containers.${app}.ipv4}"
      "--tty=true"
      "--stop-signal=SIGINT"
      "--cap-drop=ALL"
      "--cap-add=CHOWN"
      "--cap-add=SETGID"
      "--cap-add=SETUID"
      "--cap-add=DAC_OVERRIDE"
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
      rule = "Host(`search.${configVars.domain2}`)";
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
            url = "http://${configVars.containerServices.${app}.containers.${app}.ipv4}:8080";
          }
        ];
      };
    };
  };

}