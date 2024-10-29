{ 
  pkgs, 
  configVars,
  ... 
}: 

let
  app = "uptime-kuma";
in

{

  services.${app}.enable = true; 

  services.traefik.dynamicConfigOptions.http = {
    routers.${app} = {
      entrypoints = ["websecure"];
      rule = "Host(`${app}.${configVars.domain3}`)";
      service = "${app}";
      middlewares = [
        #"auth" 
        "secure-headers"
      ];
      tls = {
        certResolver = "cloudflareDns";
        options = "tls-13@file";
      };
    };
    services.${app} = {
      #settings = {
      #  PORT = "4100";
      #};
      loadBalancer = {
        passHostHeader = true;
        servers = [
        {
          url = "http://localhost:3001";
        }
        ];
      };
    };
  };

}