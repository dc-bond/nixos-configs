{ 
  config,
  lib,
  pkgs, 
  configVars,
  ... 
}: 

let
  app = "pihole";
in

{
  
  sops = {
    secrets = {
      piholeWebPasswd = {};
    };
    templates = {
      "${app}-env".content = ''
        TZ=America/New_York
        WEBPASSWORD=${config.sops.placeholder.piholeWebPasswd}
        FTLCONF_LOCAL_IPV4=${configVars.cypressLanIp}
        VIRTUAL_HOST=${app}-test.${configVars.domain2}
      '';
    };
  };

  virtualisation.oci-containers.containers."${app}" = {
    image = "docker.io/${app}/${app}:2024.07.0"; # https://hub.docker.com/r/pihole/pihole/tags
    autoStart = true;
    environmentFiles = [ config.sops.templates."${app}-env".path ];
    #environment = {
    #  #PIHOLE_DNS_ = unbound#5333
    #};
    log-driver = "journald";
    ports = [ # docker daemon automatically opens firewall ports
      "5399:53/tcp"
      "5399:53/udp"
    ];
    volumes = [ "${app}:/etc" ];
    extraOptions = [
      "--network=${app}"
      "--ip=${configVars.piholeIp}"
      "--tty=true"
      "--stop-signal=SIGINT"
    ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.${app}.entrypoints" = "websecure";
      "traefik.http.routers.${app}.rule" = "Host(`${app}-test.${configVars.domain2}`)";
      "traefik.http.routers.${app}.tls" = "true";
      "traefik.http.routers.${app}.tls.options" = "tls-13@file";
      "traefik.http.routers.${app}.middlewares" = "secure-headers@file";
      "traefik.http.services.${app}.loadbalancer.server.port" = "80"; # port for browser interface
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
          docker network inspect ${app} || docker network create --subnet ${configVars.piholeSubnet} --driver bridge --scope local --attachable ${app}
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