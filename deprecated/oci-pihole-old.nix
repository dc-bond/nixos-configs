{ 
  config,
  lib,
  pkgs, 
  configVars,
  dockerServiceRecoveryScript,
  ... 
}: 

let

  app = "pihole";
  app2 = "unbound";
  recoveryPlan = {
    restoreItems = [
      "/var/lib/docker/volumes/${app}"
      "/var/lib/docker/volumes/${app2}"
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
      piholeWebPasswd = {};
    };
    templates = {
      "${app}-env".content = ''
        TZ=America/New_York
        WEBPASSWORD=${config.sops.placeholder.piholeWebPasswd}
        FTLCONF_LOCAL_IPV4=${configVars.hosts."${config.networking.hostName}".networking.ipv4}
        VIRTUAL_HOST=${app}.${configVars.domain2}
      '';
    };
  };

  virtualisation.oci-containers.containers = {

    "${app}" = {
      image = "docker.io/${app}/${app}:2024.07.0";
      autoStart = true;
      environmentFiles = [ config.sops.templates."${app}-env".path ];
      environment = {
        PIHOLE_DNS_ = "${configVars.containerServices.${app}.containers.${app2}.ipv4}#53"; # must be in environment and not environmentFile because of nix formatting issue
      };
      log-driver = "journald";
      ports = if config.networking.hostName == "juniper"
        then [ # for juniper on VPS - only listen on tailscale interface
          "${configVars.hosts."${config.networking.hostName}".networking.tailscaleIp}:53:53/tcp"
          "${configVars.hosts."${config.networking.hostName}".networking.tailscaleIp}:53:53/udp"
        ]
        else [ # for aspen on LAN - bind to all interfaces for various devices to access (from LAN, from tailscale, etc.)
          "0.0.0.0:53:53/tcp"
          "0.0.0.0:53:53/udp"
        ];
      volumes = [ 
        "${app}:/etc"
      ];
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
        "traefik.http.routers.${app}.middlewares" = "trusted-allow@file,secure-headers@file";
        "traefik.http.services.${app}.loadbalancer.server.port" = "80"; # port for browser interface
      };
    };

    "${app2}" = {
      image = "docker.io/mvance/${app2}:1.22.0"; # https://github.com/MatthewVance/unbound-docker
      autoStart = true;
      log-driver = "journald";
      volumes = [ "${app2}:/opt/unbound/etc/unbound" ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.containerServices.${app}.containers.${app2}.ipv4}"
        "--tty=true"
        "--stop-signal=SIGINT"
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
          "docker-volume-${app}.service"
          "docker-${app2}.service"
        ];
        requires = [
          "docker-volume-${app}.service"
          "docker-${app2}.service"
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
      "docker-${app2}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-volume-${app2}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app2}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      "docker-volume-${app2}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app2} || docker volume create ${app2}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };
    };
    targets."docker-${app}-root" = {
      unitConfig = {
        Description = "root target for docker-${app} and docker-${app2}";
      };
      wantedBy = ["multi-user.target"];
    };
  }; 

}