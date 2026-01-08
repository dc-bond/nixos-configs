{
pkgs,
config,
configVars,
lib,
...
}:

{

  systemd.tmpfiles.rules = [
    "L+ /var/www/weekly-recipes.opticon.dev - - - - /var/lib/nextcloud/data/Chris\\040Bond/files/Personal/misc/weekly-recipes.opticon.dev"
    "L+ /var/www/gatlinburg2026.dcbond.com - - - - /var/lib/nextcloud/data/Chris\\040Bond/files/Bond\\040Family/Travel/2026/April\\040-\\040Gatlinburg\\040TN/gatlinburg2026.dcbond.com"
  ];

  services = {

    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {

        "weekly-recipes.${configVars.domain2}" = {
          enableACME = false;
          forceSSL = false;
          root = "/var/www/weekly-recipes.opticon.dev";
          listen = [
            {
              addr = "127.0.0.1";
              port = 9016;
            }
          ];
        };

        "gatlinburg2026.${configVars.domain1}" = {
          enableACME = false;
          forceSSL = false;
          root = "/var/www/gatlinburg2026.dcbond.com";
          listen = [
            {
              addr = "127.0.0.1";
              port = 9017;
            }
          ];
        };

      };
    };

    authelia.instances."${configVars.domain1Short}".settings.access_control.rules = [
      {
        domain = [ "gatlinburg2026.${configVars.domain1}" ];
        subject = [
          "user:admin"
          "user:danielle-bond"
          "user:guest"
        ];
        policy = "one_factor";
      }
    ];
       
    traefik = {

      dynamicConfigOptions.http = {
        routers = {

          "weekly-recipes" = {
            entrypoints = ["websecure"];
            rule = "Host(`weekly-recipes.${configVars.domain2}`)";
            service = "weekly-recipes";
            middlewares = [
              "trusted-allow"
              "secure-headers"
            ];
            tls = {
              certResolver = "cloudflareDns";
              options = "tls-13@file";
            };
          };

          "gatlinburg2026" = {
            entrypoints = ["websecure"];
            rule = "Host(`gatlinburg2026.${configVars.domain1}`)";
            service = "gatlinburg2026";
            middlewares = [
              "authelia-dcbond"
              "secure-headers"
            ];
            tls = {
              certResolver = "cloudflareDns";
              options = "tls-13@file";
            };
          };
        };

        services = {

          "weekly-recipes" = {
            loadBalancer = {
              passHostHeader = true;
              servers = [
                {
                  url = "http://127.0.0.1:9016";
                }
              ];
            };
          };

          "gatlinburg2026" = {
            loadBalancer = {
              passHostHeader = true;
              servers = [
                {
                  url = "http://127.0.0.1:9017";
                }
              ];
            };
          };

        };
      };
    };

  };

}