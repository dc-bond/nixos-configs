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

    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."cloud.${configVars.domain3}".listen = [{addr = "127.0.0.1"; port = 4411;}];
    };

    ${app} = {
      enable = true;
      hostName = "cloud.${configVars.domain3}";
      package = pkgs.nextcloud30; # manually increment with upgrades
      database.createLocally = true; # creates database
      configureRedis = true; # creates redis instance
      #caching.redis = true; # load redis into nextcloud php, auto enabled if configureRedis is true
      maxUploadSize = "20G"; # max upload size
      https = true;
      autoUpdateApps.enable = true;
      extraAppsEnable = true;
      extraApps = with config.services.nextcloud.package.packages.apps; { # list of nextcloud apps
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
        inherit calendar contacts user_oidc tasks;
      };
      settings = {
        trusted_proxies = ["127.0.0.1"];
        overwriteProtocol = "https";
        default_phone_region = "US";
        log_type = "file";
        loglevel = 2; # info
        allow_local_remote_servers = true; # required for OIDC
        user_oidc.use_pkce = true; # required for OIDC
        maintenance_window_start = 1;
        #allowed_admin_ranges = [
        #  #"127.0.0.1/8"
        #  #"192.168.0.0/16"
        #];
      };
      config = {
        dbtype = "pgsql"; # postgres database
        dbname = "${app}";
        dbuser = "${app}";
        adminuser = "admin";
        adminpassFile = "${config.sops.secrets.nextcloudAdminPasswd.path}";
      };
      phpOptions = {
        "opcache.interned_strings_buffer" = "16"; # suggested by nextcloud's health check
      };
    };

    postgresqlBackup = { # nightly database backup
      enable = true;
      databases = ["${app}"];
      startAt = "*-*-* 01:15:00";
    };

  };
  
  services.traefik.dynamicConfigOptions.http = {
    routers.${app} = {
      entrypoints = ["websecure"];
      rule = "Host(`cloud.${configVars.domain3}`)";
      service = "${app}";
      middlewares = [
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