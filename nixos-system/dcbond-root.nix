{ 
pkgs,
config,
configVars, 
lib,
... 
}: 

{

  services = {

    traefik.dynamicConfigOptions.http = {
      routers = {
        "${configVars.domain1}-redirect" = {
          entrypoints = ["websecure"];
          rule = "Host(`${configVars.domain1}`)";
          service = "noop@internal";
          middlewares = [
            "secure-headers"
            "${configVars.domain1}-redirect"
          ];
          tls = {
            certResolver = "cloudflareDns";
            options = "tls-13@file";
          };
        };
      };
      middlewares = {
        "${configVars.domain1}-redirect".redirectRegex = {
          permanent = true;
          regex = "^https://${configVars.domain1}/$";
          replacement = "https://www.linkedin.com/in/dcbond";
        };
      };
    };

  };

}