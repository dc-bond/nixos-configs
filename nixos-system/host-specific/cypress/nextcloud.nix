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
      extraApps = {
        inherit (config.services.nextcloud.package.packages.apps) contacts tasks;
        oidc_login = pkgs.fetchNextcloudApp {
          sha256 = "sha256-DrbaKENMz2QJfbDKCMrNGEZYpUEvtcsiqw9WnveaPZA=";
          url = "https://github.com/pulsejet/nextcloud-oidc-login/releases/download/v3.2.0/oidc_login.tar.gz";
          license = "gpl3";
        };
      };
      #extraApps = with config.services.nextcloud.package.packages.apps; { # list of nextcloud apps
      #  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json # user_oidc
      #  inherit contacts tasks;
      #  nextcloud-oidc-login = pkgs.fetchNextcloudApp {
      #    sha256 = "sha256-DrbaKENMz2QJfbDKCMrNGEZYpUEvtcsiqw9WnveaPZA=";
      #    url = "https://github.com/pulsejet/nextcloud-oidc-login/releases/download/v3.2.0/oidc_login.tar.gz";
      #    license = "gpl3";
      #  };
      #};
      settings = {
        enabledPreviewProviders = [
          "OC\\Preview\\BMP"
          "OC\\Preview\\GIF"
          "OC\\Preview\\JPEG"
          "OC\\Preview\\Krita"
          "OC\\Preview\\MarkDown"
          "OC\\Preview\\MP3"
          "OC\\Preview\\OpenDocument"
          "OC\\Preview\\PNG"
          "OC\\Preview\\TXT"
          "OC\\Preview\\XBitmap"
          "OC\\Preview\\HEIC"
        ];
        trusted_proxies = ["127.0.0.1"];
        overwriteProtocol = "https";
        default_phone_region = "US";
        log_type = "file";
        loglevel = 2; # info
        maintenance_window_start = 1;
        #allowed_admin_ranges = [
        #  #"127.0.0.1/8"
        #  #"192.168.0.0/16"
        #];
        
        # user_oidc:
        #allow_local_remote_servers = true; # required for OIDC
        #user_oidc = {
        #  "use_pkce" = true; # required for OIDC
        #  #"oidc_login_auto_redirect" = true; # doesn't work, must manual occ command: 'nextcloud-occ config:app:set --value=0 user_oidc allow_multiple_user_backends'
        #  #"single_logout" = true;
        #};

        # openid connect oidc:
        allow_user_to_change_display_name = false;
        lost_password_link = "disabled";
        oidc_login_provider_url = "https://identity.opticon.dev";
        oidc_login_client_id = "7Au52dmVWwvAGdqvrsLatNjedPoSIfQw~UWRj.M24VWhhlDp8v_tXUtePMvCz9pn~Vt1EVBc";
        oidc_login_client_secret = "5EPje~2UG6pT~ZqhR.JMnCPm~XvfWv~nbC-vxMJSlUbwbv5b7hSi2_FKeWbLPJK6cQkXOyAx";
        oidc_login_auto_redirect = true; # bypass Nextcloud login screen and go right to identity provider
        oidc_login_end_session_redirect = true;
        oidc_login_logout_url = "https://identity.opticon.dev";
        oidc_login_button_text = "Login with Opticon Identify Verification";
        oidc_login_hide_password_form = false;
        oidc_login_use_id_token = true;
        oidc_login_default_group = "oidc";
        oidc_login_use_external_storage = false;
        oidc_login_scope = "openid profile email groups";
        oidc_login_proxy_ldap = false;
        oidc_login_disable_registration = true;
        oidc_login_redir_fallback = false;
        oidc_login_tls_verify = true;
        oidc_create_groups = false;
        oidc_login_webdav_enabled = false;
        oidc_login_password_authentication = false;
        oidc_login_public_key_caching_time = 86400;
        oidc_login_min_time_between_jwks_requests = 10;
        oidc_login_well_known_caching_time = 86400;
        oidc_login_update_avatar = false;
        oidc_login_code_challenge_method = "S256";
        oidc_login_attributes = {
          "id" = "preferred_username";
          "name" = "name";
          "mail" = "email";
          "groups" = "groups";
        };

      };
      config = {
        dbtype = "pgsql";
        dbhost = "/run/postgresql";
        dbname = "${app}";
        dbuser = "${app}";
        adminuser = "Admin";
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