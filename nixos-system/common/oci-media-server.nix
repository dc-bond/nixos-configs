{ 
  config,
  lib,
  pkgs, 
  configVars,
  ... 
}: 

let
  app = "media-server";
  app1 = "media-server-vpn";
  app2 = "sabnzbd";
  app3 = "sonarr";
  app4 = "radarr";
  app5 = "prowlarr";
  app6 = "jellyseerr";
  app7 = "jellyfin";
in

{

  networking.wireguard.enable = true;
  
  sops = {
    secrets = {
      vpnPrivateKey = {};
    };
    templates = {
      "${app1}-env".content = ''
        TZ=America/New_York
        PRIVATE_KEY=${config.sops.placeholder.vpnPrivateKey}
        NET_LOCAL=192.168.1.0/24
      '';
    };
  };

  services.traefik.dynamicConfigOptions.http.middlewares.jellyfin-trusted-allow.ipAllowList.sourceRange = [
    "192.168.1.0/24" # Home-VLAN
    "192.168.4.0/27" # IOT-VLAN for Rokus
    "${configVars.aspenLanIp}" # for Uptime Kuma
    "${configVars.thinkpadTailscaleIp}" # thinkpad tailscale IP
    "${configVars.chrisIphone15TailscaleIp}" # chris iPhone tailscale IP
    "${configVars.daniellePixel7aTailscaleIp}" # danielle pixel 7a tailscale IP
    "${configVars.sydneyIphone6TailscaleIp}" # sydney iphone 6 tailscale IP
  ];

  virtualisation.oci-containers.containers = {

    "${app1}" = {
      image = "docker.io/bubuntux/nordlynx:2025-01-01"; # https://hub.docker.com/r/bubuntux/nordlynx/tags
      autoStart = true;
      log-driver = "journald";
      environmentFiles = [ config.sops.templates."${app1}-env".path ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.arrVpnIp}"
        "--sysctl=net.ipv6.conf.all.disable_ipv6=1"
        "--cap-add=NET_ADMIN"
        "--privileged"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${app2}.service" = "${app2}";
        "traefik.http.routers.${app2}.entrypoints" = "websecure";
        "traefik.http.routers.${app2}.rule" = "Host(`${app2}.${configVars.domain2}`)";
        "traefik.http.routers.${app2}.tls" = "true";
        "traefik.http.routers.${app2}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app2}.middlewares" = "trusted-allow@file,secure-headers@file";
        "traefik.http.services.${app2}.loadbalancer.server.port" = "8080"; # sabnzbd
        "traefik.http.routers.${app3}.service" = "${app3}";
        "traefik.http.routers.${app3}.entrypoints" = "websecure";
        "traefik.http.routers.${app3}.rule" = "Host(`${app3}.${configVars.domain2}`)";
        "traefik.http.routers.${app3}.tls" = "true";
        "traefik.http.routers.${app3}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app3}.middlewares" = "trusted-allow@file,secure-headers@file";
        "traefik.http.services.${app3}.loadbalancer.server.port" = "8989"; # sonarr
        "traefik.http.routers.${app4}.service" = "${app4}";
        "traefik.http.routers.${app4}.entrypoints" = "websecure";
        "traefik.http.routers.${app4}.rule" = "Host(`${app4}.${configVars.domain2}`)";
        "traefik.http.routers.${app4}.tls" = "true";
        "traefik.http.routers.${app4}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app4}.middlewares" = "trusted-allow@file,secure-headers@file";
        "traefik.http.services.${app4}.loadbalancer.server.port" = "7878"; # radarr
        "traefik.http.routers.${app5}.service" = "${app5}";
        "traefik.http.routers.${app5}.entrypoints" = "websecure";
        "traefik.http.routers.${app5}.rule" = "Host(`${app5}.${configVars.domain2}`)";
        "traefik.http.routers.${app5}.tls" = "true";
        "traefik.http.routers.${app5}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app5}.middlewares" = "trusted-allow@file,secure-headers@file";
        "traefik.http.services.${app5}.loadbalancer.server.port" = "9696"; # prowlarr
        "traefik.http.routers.${app6}.service" = "${app6}";
        "traefik.http.routers.${app6}.entrypoints" = "websecure";
        "traefik.http.routers.${app6}.rule" = "Host(`${app6}.${configVars.domain2}`)";
        "traefik.http.routers.${app6}.tls" = "true";
        "traefik.http.routers.${app6}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app6}.middlewares" = "trusted-allow@file,secure-headers@file";
        "traefik.http.services.${app6}.loadbalancer.server.port" = "5055"; # jellyseerr
        "traefik.http.routers.${app7}.service" = "${app7}";
        "traefik.http.routers.${app7}.entrypoints" = "websecure";
        "traefik.http.routers.${app7}.rule" = "Host(`${app7}.${configVars.domain2}`)";
        "traefik.http.routers.${app7}.tls" = "true";
        "traefik.http.routers.${app7}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app7}.middlewares" = "jellyfin-trusted-allow@file,secure-headers@file";
        "traefik.http.services.${app7}.loadbalancer.server.port" = "8096"; # jellyfin
      };
    };

    "${app2}" = {
      image = "lscr.io/linuxserver/${app2}:4.4.1-ls202"; # https://github.com/linuxserver/docker-sabnzbd/releases
      autoStart = true;
      volumes = [ 
        "${app2}:/config" 
        "${config.drives.storageDrive1}/media/usenet:/media/usenet:rw" # bind mount for downloads
      ];
      environment = {
        PUID = "0";
        PGID = "0";
        TZ = "America/New_York";
      };
      log-driver = "journald";
      dependsOn = ["${app1}"];
      extraOptions = [
        "--network=container:${app1}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };
    
    "${app3}" = {
      image = "lscr.io/linuxserver/${app3}:4.0.13.2932-ls271"; # https://github.com/linuxserver/docker-sonarr/releases
      autoStart = true;
      volumes = [ 
        "${app3}:/config" 
        "${config.drives.storageDrive1}/media:/media:rw" # bind mount for media access
      ];
      environment = {
        PUID = "0";
        PGID = "0";
        TZ = "America/New_York";
      };
      log-driver = "journald";
      dependsOn = ["${app1}"];
      extraOptions = [
        "--network=container:${app1}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };
    
    "${app4}" = {
      image = "lscr.io/linuxserver/${app4}:5.18.4.9674-ls260"; # https://github.com/linuxserver/docker-radarr/releases
      autoStart = true;
      volumes = [ 
        "${app4}:/config" 
        "${config.drives.storageDrive1}/media:/media:rw" # bind mount for media access
      ];
      environment = {
        PUID = "0";
        PGID = "0";
        TZ = "America/New_York";
      };
      log-driver = "journald";
      dependsOn = ["${app1}"];
      extraOptions = [
        "--network=container:${app1}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };
    
    "${app5}" = {
      image = "lscr.io/linuxserver/${app5}:1.30.2.4939-ls105"; # https://github.com/linuxserver/docker-prowlarr/releases
      autoStart = true;
      volumes = [ "${app5}:/config" ];
      environment = {
        PUID = "0";
        PGID = "0";
        TZ = "America/New_York";
      };
      log-driver = "journald";
      dependsOn = ["${app1}"];
      extraOptions = [
        "--network=container:${app1}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

    "${app6}" = {
      image = "docker.io/fallenbagel/${app6}:2.3.0"; # https://hub.docker.com/r/fallenbagel/jellyseerr/tags
      autoStart = true;
      volumes = [ "${app6}:/app/config" ];
      log-driver = "journald";
      dependsOn = ["${app1}"];
      extraOptions = [
        "--network=container:${app1}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

    "${app7}" = {
      image = "lscr.io/linuxserver/${app7}:10.10.6ubu2404-ls53"; # https://github.com/linuxserver/docker-jellyfin/releases
      autoStart = true;
      environment = { NVIDIA_VISIBLE_DEVICES = "all"; }; # enable GPU utilization
      volumes = [ 
        "${app7}:/config" 
        "${config.drives.storageDrive1}/media/television:/data/tvshows:ro" # bind-mount to provide container access to tv shows
        "${config.drives.storageDrive1}/media/movies:/data/movies:ro" # ditto for movies
        "${config.drives.storageDrive1}/media/music:/data/music:ro" # ditto for music
        "${config.drives.storageDrive1}/media/yt-downloads:/data/yt-downloads:ro" # ditto for youtube downloads
      ];
      log-driver = "journald";
      dependsOn = ["${app1}"];
      extraOptions = [
        "--network=container:${app1}"
        "--tty=true"
        "--stop-signal=SIGINT"
        "--device=nvidia.com/gpu=all" # enable GPU utilization
      ];
    };

  };

  systemd = {
    services = { 

      "docker-network-${app}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${pkgs.docker}/bin/docker network rm -f ${app}";
        };
        script = ''
          docker network inspect ${app} || docker network create --subnet ${configVars.arrStackSubnet} --driver bridge --scope local --attachable ${app}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };

      "docker-${app1}" = {
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

      "docker-${app2}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-${app1}.service"
          "docker-volume-${app2}.service"
        ];
        requires = [
          "docker-${app1}.service"
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
      
      "docker-${app3}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-${app1}.service"
          "docker-volume-${app3}.service"
        ];
        requires = [
          "docker-${app1}.service"
          "docker-volume-${app3}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      "docker-volume-${app3}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app3} || docker volume create ${app3}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };

      "docker-${app4}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-${app1}.service"
          "docker-volume-${app4}.service"
        ];
        requires = [
          "docker-${app1}.service"
          "docker-volume-${app4}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      "docker-volume-${app4}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app4} || docker volume create ${app4}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };

      "docker-${app5}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-${app1}.service"
          "docker-volume-${app5}.service"
        ];
        requires = [
          "docker-${app1}.service"
          "docker-volume-${app5}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      "docker-volume-${app5}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app5} || docker volume create ${app5}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };

      "docker-${app6}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-${app1}.service"
          "docker-volume-${app6}.service"
        ];
        requires = [
          "docker-${app1}.service"
          "docker-volume-${app6}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      "docker-volume-${app6}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app6} || docker volume create ${app6}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };

      "docker-${app7}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-${app1}.service"
          "docker-volume-${app7}.service"
        ];
        requires = [
          "docker-${app1}.service"
          "docker-volume-${app7}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      "docker-volume-${app7}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app7} || docker volume create ${app7}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };

    };
    targets."docker-${app}-root" = {
      unitConfig = {
        Description = "root target for ${app} containers";
      };
      wantedBy = ["multi-user.target"];
    };
  }; 

}