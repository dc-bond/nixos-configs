{ 
  pkgs, 
  configVars,
  ... 
}: 

let
  app = "pinchflat";
in

{

  sops.secrets.pinchflatSecretKeyBase = {};

  services.${app} = {
    enable = true;
    logLevel = "debug";
    extraConfig = {
      TZ = "America/New_York";
      SECRET_KEY_BASE = "${config.sops.placeholder.pinchflatSecretKeyBase}";
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
          url = "http://127.0.0.1:8945";
        }
        ];
      };
    };
  };

}