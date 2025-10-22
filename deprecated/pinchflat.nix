{ 
  pkgs,
  lib,
  config,
  configVars,
  ... 
}: 

let
  app = "pinchflat";
in

{
  
  users = {
    users.pinchflat = {
      isSystemUser = true;
      group = "pinchflat";
    };
    groups.pinchflat = {};
  };

  systemd.services.pinchflat.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "pinchflat";
    Group = "pinchflat";
  };

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
    logLevel = "warning";
    secretsFile = "/run/secrets/rendered/pinchflat-env";
    mediaDir = "${config.hostSpecificConfigs.storageDrive1}/media/yt-downloads";
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