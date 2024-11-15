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

    nginx.virtualHosts."cloud.${configVars.domain3}".listen = [ { addr = "127.0.0.1"; port = 4411; } ];
  
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
        inherit calendar contacts notes tasks;
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
    postgresqlBackup = { # nightly database backup
      enable = true;
      startAt = "*-*-* 01:15:00";
    };
  };
  
  services.traefik.dynamicConfigOptions.http = {
    routers.${app} = {
      entrypoints = ["websecure"];
      rule = "Host(`cloud.${configVars.domain3}`)";
      service = "${app}";
      middlewares = [
        "authelia"
        "secure-headers"
        "nextcloud-redirect-regex"
      ];
      tls = {
        certResolver = "cloudflareDns";
        options = "tls-13@file";
      };
    };
    middlewares.nextcloud-redirect-regex.redirectRegex = {
      permanent = true;
      regex = "https://(.*)/.well-known/(card|cal)dav";
      replacement = "https://\${1}/remote.php/dav/";
    };
    services.${app} = {
      loadBalancer = {
        passHostHeader = true;
        servers = [
        {
          url = "http://127.0.0.1:4411";
        }
        ];
      };
    };
  };

}