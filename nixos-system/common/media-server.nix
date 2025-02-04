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
              url = "http://127.0.0.1:8080";
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