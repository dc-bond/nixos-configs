{ 
  pkgs, 
  configVars,
  ... 
}: 

let
  app = "stirling-pdf";
in

{

  services.${app} = {
    enable = true;
    environment = { 
      SERVER_PORT = 8081; 
      INSTALL_BOOK_AND_ADVANCED_HTML_OPS = "true";
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.${app} = {
      entrypoints = ["websecure"];
      rule = "Host(`${app}.${configVars.domain2}`)";
      service = "${app}";
      middlewares = [
        "trusted-allow"
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
          url = "http://127.0.0.1:8081";
        }
        ];
      };
    };
  };

}