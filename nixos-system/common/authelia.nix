{ 
  #config, 
  pkgs, 
  configVars,
  ... 
}:

let
  app = "authelia";
in

{

  services.${app} = {
    enable = true; 
    settings = {

    };
  }; 

  services.traefik.dynamicConfigOptions.http = {
    routers.${app} = {
      entrypoints = ["websecure"];
      rule = "Host(`identity.${configVars.domain3}`)";
      service = ${app};
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