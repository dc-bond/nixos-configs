{ 
  pkgs,
  config,
  configVars,
  ... 
}: 

let
  app = "pinchflat";
in

{

  sops = {
    secrets.pinchflatSecretKeyBase = {};
    templates."pinchflat-env" = {
      content = ''
        SECRET_KEY_BASE = ${config.sops.placeholder.pinchflatSecretKeyBase}
      '';
    };
  };

  services.${app} = {
    enable = true;
    logLevel = "warn";
    secretsFile = "/run/secrets/rendered/pinchflat";
    mediaDir = "${config.drives.storageDrive1}/media/yt-downloads";
    extraConfig = {
      TZ = "America/New_York";
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