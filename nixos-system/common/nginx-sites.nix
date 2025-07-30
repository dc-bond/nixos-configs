{ 
pkgs,
config,
configVars, 
lib,
... 
}: 

{

  systemd.tmpfiles.rules = [
    "d /var/www 0755 root root -"
    "d /var/www/2025-hawaii 0755 root root -"
  ];

  services = {

    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "2025-hawaii.${configVars.domain2}" = {
          enableACME = false;
          forceSSL = false;
          root = "/var/www/2025-hawaii";
          listen = [
            {
              addr = "127.0.0.1"; 
              port = 9015;
            }
          ];
        };
      };
    };
       
    traefik = {

      dynamicConfigOptions.http = {
        routers = {
          "2025-hawaii" = {
            entrypoints = ["websecure"];
            rule = "Host(`2025-hawaii.${configVars.domain2}`)";
            service = "2025-hawaii";
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
          "2025-hawaii" = {
            loadBalancer = {
              passHostHeader = true;
              servers = [
                {
                  url = "http://127.0.0.1:9015";
                }
              ];
            };
          };
        };
      };
    };

  };

}