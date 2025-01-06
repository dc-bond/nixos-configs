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

  systemd.services."${app}-setup" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  services = {

    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."cloud.${configVars.domain2}".listen = [{addr = "127.0.0.1"; port = 4411;}];
    };

    ${app} = {
      enable = true;
      hostName = "cloud.${configVars.domain2}";
      package = pkgs.nextcloud30; # manually increment with upgrades
      database.createLocally = false; # enables postgres service if true, manual setup below
      configureRedis = true; # creates redis instance
      #caching.redis = true; # load redis into nextcloud php, auto enabled if configureRedis is true
      maxUploadSize = "30G"; # max upload size
      https = true;
      autoUpdateApps.enable = true;
      extraAppsEnable = true;
      extraApps = with config.services.nextcloud.package.packages.apps; { # list of nextcloud apps
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
        inherit contacts user_oidc tasks;
      };
      settings = {
        trusted_proxies = ["127.0.0.1"];
        overwriteProtocol = "https";
        default_phone_region = "US";
        log_type = "file";
        loglevel = 2; # info
        allow_local_remote_servers = true; # required for OIDC
        user_oidc.use_pkce = true; # required for OIDC
        #oidc_login_auto_redirect = true; # doesn't work, must manual occ command: 'nextcloud-occ config:app:set --value=0 user_oidc allow_multiple_user_backends'
        maintenance_window_start = 1;
        #allowed_admin_ranges = [
        #  #"127.0.0.1/8"
        #  #"192.168.0.0/16"
        #];
      };
      config = {
        dbtype = "pgsql";
        dbhost = "/run/postgresql";
        dbname = "${app}";
        dbuser = "${app}";
        adminuser = "admin";
        adminpassFile = "${config.sops.secrets.nextcloudAdminPasswd.path}";
      };
      phpOptions = {
        "opcache.interned_strings_buffer" = "16"; # suggested by nextcloud's health check
      };
    };

    postgresql = {
      enable = true;
      ensureDatabases = ["${app}"];
      ensureUsers = [
        {
          name = "${app}";
          ensureDBOwnership = true;
          ensureClauses.createdb = true;
        }
      ];
    };

    postgresqlBackup = {
      databases = ["${app}"];
    };
  
    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`cloud.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [
          #"authelia" # OIDC login setup and working so traditional authelia middleware not necessary
          "secure-headers"
          #"nextcloud-redirect-login"
          "nextcloud-redirect-dav"
        ];
        tls = {
          certResolver = "cloudflareDns";
          options = "tls-13@file";
        };
      };
      middlewares = {
        #nextcloud-redirect-login.redirectRegex = {
        #  permanent = true;
        #  regex = "^https://nextcloud\\.opticon\\.dev$";
        #  replacement = "https://nextcloud.opticon.dev/apps/user_oidc/login/1";
        #};
        nextcloud-redirect-dav.redirectRegex = {
          permanent = true;
          regex = "https://(.*)/.well-known/(card|cal)dav";
          replacement = "https://\${1}/remote.php/dav/";
        };
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

  };

}