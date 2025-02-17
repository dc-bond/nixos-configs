{
  pkgs,
  lib,
  config,
  configVars,
  ...
}: 

let
  app1 = "jellyfin";
  app2 = "jellyseerr";
  app3 = "sabnzbd";
  app4 = "prowlarr";
  app5 = "radarr";
  app6 = "sonarr";
  #app7 = "nordlynx";
in

{

  fileSystems."/mnt/transcodes" = {
    fsType = "tmpfs";
    options = [ 
      "rw" 
      "nosuid" 
      "inode64" 
      "nodev" 
      "noexec" 
      "size=2G" 
    ];
  };

  nixpkgs.config.permittedInsecurePackages = [ # workaround for sonarr in 24.11
    "aspnetcore-runtime-6.0.36"
    "aspnetcore-runtime-wrapped-6.0.36"
    "dotnet-sdk-6.0.428"
    "dotnet-sdk-wrapped-6.0.428"
  ];
  
  networking.wireguard.enable = true;

  #sops = {
  #  secrets = {
  #    vpnPrivateKey = {};
  #  };
  #  templates = {
  #    "${app7}-env".content = ''
  #      TZ=America/New_York
  #      PRIVATE_KEY=${config.sops.placeholder.vpnPrivateKey}
  #      NET_LOCAL=192.168.1.0/24
  #    '';
  #  };
  #};

  #virtualisation.oci-containers.containers.${app7} = {
  #  image = "docker.io/bubuntux/nordlynx:2025-01-01"; # https://hub.docker.com/r/bubuntux/nordlynx/tags
  #  autoStart = true;
  #  log-driver = "journald";
  #  environmentFiles = [ config.sops.templates."${app7}-env".path ];
  #  extraOptions = [
  #    "--network=host"
  #    #"--ip=${configVars.chromiumVpnIp}"
  #    #"--sysctl=net.ipv6.conf.all.disable_ipv6=1"
  #    "--cap-add=NET_ADMIN"
  #    "--privileged"
  #    "--tty=true"
  #    "--stop-signal=SIGINT"
  #  ];
  #  #labels = {
  #  #  "traefik.enable" = "true";
  #  #  "traefik.http.routers.${app}.entrypoints" = "websecure";
  #  #  "traefik.http.routers.${app}.rule" = "Host(`${app2}.${configVars.domain2}`)";
  #  #  "traefik.http.routers.${app}.tls" = "true";
  #  #  "traefik.http.routers.${app}.tls.options" = "tls-13@file";
  #  #  "traefik.http.routers.${app}.middlewares" = "secure-headers@file";
  #  #  "traefik.http.services.${app}.loadbalancer.server.port" = "3000"; # port for chromium container
  #  #};
  #};

  services = {

    ${app1} = {
      enable = true;
      cacheDir = "/mnt/transcodes";
    };

    ${app2}.enable = true;

    ${app3}.enable = true;

    ${app4}.enable = true;

    ${app5}.enable = true;

    ${app6}.enable = true;

    traefik.dynamicConfigOptions.http = {
      routers = {
        ${app1} = {
          entrypoints = ["websecure"];
          rule = "Host(`${app1}.${configVars.domain2}`)";
          service = "${app1}";
          middlewares = [
            "secure-headers"
          ];
          tls = {
            certResolver = "cloudflareDns";
            options = "tls-13@file";
          };
        };
        ${app2} = {
          entrypoints = ["websecure"];
          rule = "Host(`${app2}.${configVars.domain2}`)";
          service = "${app2}";
          middlewares = [
            "secure-headers"
          ];
          tls = {
            certResolver = "cloudflareDns";
            options = "tls-13@file";
          };
        };
        ${app3} = {
          entrypoints = ["websecure"];
          rule = "Host(`${app3}.${configVars.domain2}`)";
          service = "${app3}";
          middlewares = [
            "secure-headers"
          ];
          tls = {
            certResolver = "cloudflareDns";
            options = "tls-13@file";
          };
        };
        ${app4} = {
          entrypoints = ["websecure"];
          rule = "Host(`${app4}.${configVars.domain2}`)";
          service = "${app4}";
          middlewares = [
            "secure-headers"
          ];
          tls = {
            certResolver = "cloudflareDns";
            options = "tls-13@file";
          };
        };
        ${app5} = {
          entrypoints = ["websecure"];
          rule = "Host(`${app5}.${configVars.domain2}`)";
          service = "${app5}";
          middlewares = [
            "secure-headers"
          ];
          tls = {
            certResolver = "cloudflareDns";
            options = "tls-13@file";
          };
        };
        ${app6} = {
          entrypoints = ["websecure"];
          rule = "Host(`${app6}.${configVars.domain2}`)";
          service = "${app6}";
          middlewares = [
            "secure-headers"
          ];
          tls = {
            certResolver = "cloudflareDns";
            options = "tls-13@file";
          };
        };
      };
      services = {
        ${app1} = {
          loadBalancer = {
            passHostHeader = true;
            servers = [
            {
              url = "http://127.0.0.1:8096";
            }
            ];
          };
        };
        ${app2} = {
          loadBalancer = {
            passHostHeader = true;
            servers = [
            {
              url = "http://127.0.0.1:5055";
            }
            ];
          };
        };
        ${app3} = {
          loadBalancer = {
            passHostHeader = true;
            servers = [
            {
              url = "http://127.0.0.1:8280";
            }
            ];
          };
        };
        ${app4} = {
          loadBalancer = {
            passHostHeader = true;
            servers = [
            {
              url = "http://127.0.0.1:9696";
            }
            ];
          };
        };
        ${app5} = {
          loadBalancer = {
            passHostHeader = true;
            servers = [
            {
              url = "http://127.0.0.1:7878";
            }
            ];
          };
        };
        ${app6} = {
          loadBalancer = {
            passHostHeader = true;
            servers = [
            {
              url = "http://127.0.0.1:8989";
            }
            ];
          };
        };
      };
    };

  };

}