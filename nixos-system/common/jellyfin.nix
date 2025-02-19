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

  services = {

    ${app1} = {
      enable = true;
      cacheDir = "/mnt/transcodes";
    };
    ${app2}.enable = true;

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
      };
    };

  };

}