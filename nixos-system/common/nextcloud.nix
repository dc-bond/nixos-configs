{ 
  self, 
  config,
  configVars,
  lib, 
  pkgs, 
  ... 
}: 

let
  app = "nextcloud";
in

{

  sops = {
    secrets = {
      nextcloudAdminPasswd = {
        owner = "${config.users.users.${app}.name}";
        group = "${config.users.users.${app}.group}";
        mode = "0440";
      };
    };
  };

  services = {

    ${app} = {
      enable = true;
      hostName = "cloud.${configVars.domain3}";
      package = pkgs.nextcloud29; # manually increment with upgrades
      database.createLocally = true; # creates database
      configureRedis = true; # creates redis instance
      maxUploadSize = "20G"; # max upload size
      https = true;
      autoUpdateApps.enable = true;
      extraAppsEnable = true;
      extraApps = with config.services.nextcloud.package.packages.apps; { # list of nextcloud apps
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
        inherit calendar contacts notes tasks cookbook qownnotesapi;
        #socialsharing_telegram = pkgs.fetchNextcloudApp rec { # custom app example
        #  url =
        #    "https://github.com/nextcloud-releases/socialsharing/releases/download/v3.0.1/socialsharing_telegram-v3.0.1.tar.gz";
        #  license = "agpl3";
        #  sha256 = "sha256-8XyOslMmzxmX2QsVzYzIJKNw6rVWJ7uDhU1jaKJ0Q8k=";
        #};
      };
      settings = {
        overwriteProtocol = "https";
        default_phone_region = "US";
      };
      config = {
        dbtype = "pgsql"; # postgres databse
        adminuser = "admin";
        adminpassFile = "${config.sops.secrets.nextcloudAdminPasswd.path}";
      };
      phpOptions."opcache.interned_strings_buffer" = "16"; # suggested by nextcloud's health check
    };
    #postgresqlBackup = { # nightly databse backup
    #  enable = true;
    #  startAt = "*-*-* 01:15:00";
    #};
  };
  
  services.traefik.dynamicConfigOptions.http = {
    routers.${app} = {
      entrypoints = ["websecure"];
      rule = "Host(`cloud.${configVars.domain3}`)";
      service = "${app}";
      middlewares = [
        "auth-chain"
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
          url = "http://127.0.0.1:80";
        }
        ];
      };
    };
  };

}