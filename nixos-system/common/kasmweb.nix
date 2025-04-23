{ 
pkgs,
config,
configVars, 
lib,
... 
}: 

let
  app = "kasmweb";
  app2 = "kasm-vpn";
in

{

  services = {

    "${app}" = {
      enable = true;
      networkSubnet = "${configVars.kasmwebSubnet}";
      listenAddress = "127.0.0.1";
      listenPort = 8377;
    };

    traefik = {
      staticConfigOptions.serversTransport.insecureSkipVerify = true; 
      dynamicConfigOptions.http = {
        routers.${app} = {
          entrypoints = ["websecure"];
          rule = "Host(`${app}.${configVars.domain2}`)";
          service = "${app}";
          middlewares = [ "secure-headers" ];
          tls = {
            certResolver = "cloudflareDns";
            options = "tls-13@file";
          };
        };
        services.${app} = {
          loadBalancer = {
            passHostHeader = true;
            servers = [
            {
              url = "https://127.0.0.1:8377";
            }
            ];
          };
        };
      };
    };

  };

  networking.wireguard.enable = true;
  
  sops = {
    secrets = {
      vpnPrivateKey = {};
    };
    templates = {
      "${app2}-env".content = ''
        TZ=America/New_York
        PRIVATE_KEY=${config.sops.placeholder.vpnPrivateKey}
        NET_LOCAL=192.168.1.0/24
      '';
    };
  };

  virtualisation.oci-containers.containers = {

    "${app2}" = {
      image = "docker.io/bubuntux/nordlynx:2025-01-01"; # https://hub.docker.com/r/bubuntux/nordlynx/tags
      autoStart = true;
      log-driver = "journald";
      environmentFiles = [ config.sops.templates."${app2}-env".path ];
      extraOptions = [
        "--network=${app2}"
        "--ip=${configVars.kasmVpnIp}"
        "--sysctl=net.ipv6.conf.all.disable_ipv6=1"
        "--cap-add=NET_ADMIN"
        "--privileged"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

  };

  systemd = {
    services = { 
      "docker-network-${app2}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${pkgs.docker}/bin/docker network rm -f ${app2}";
        };
        script = ''
          docker network inspect ${app2} || docker network create --subnet ${configVars.kasmVpnSubnet} --driver bridge --scope local --attachable ${app2}
        '';
        partOf = [ "docker-${app2}-root.target" ];
        wantedBy = [ "docker-${app2}-root.target" ];
      };
      "docker-${app2}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [ "docker-network-${app2}.service" ];
        requires = [ "docker-network-${app2}.service" ];
        partOf = [ "docker-${app2}-root.target" ];
        wantedBy = [ "docker-${app2}-root.target" ];
      };
    };
    targets."docker-${app2}-root" = {
      unitConfig = {
        Description = "root target for ${app2} container stack";
      };
      wantedBy = [ "multi-user.target" ];
    };
  }; 

}