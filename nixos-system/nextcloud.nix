#nextcloud-occ config:app:set --value=0 user_oidc allow_multiple_user_backends
#nextcloud-occ maintenance:repair --include-expensive

# ============================================================================
# NEXTCLOUD DATA MIGRATION PLAN (NVMe → HDD/ZFS)
# ============================================================================
# Goal: Move entire Nextcloud state (config, apps, user data) from fast NVMe
#       to bulk storage HDD/future ZFS pool. This moves ALL state including the
#       data/ subdirectory which contains user files (photos, docs).
#
# NOTE: The 'datadir' option moves the ENTIRE state tree (config/, data/,
#       store-apps/, etc.), not just user files. Config and apps are small,
#       so the performance impact of having them on HDD is negligible.
#
# Migration Steps (run on aspen):
#   2. sudo nextcloud-occ maintenance:mode --on
#   3. sudo systemctl stop phpfpm-nextcloud nginx
#   4. sudo rsync -avxHAX --progress /var/lib/nextcloud/ /storage/nextcloud/
#      (rsync will create /storage/nextcloud/ and preserve ownership/permissions)
#   5. Verify copy: sudo diff -qr /var/lib/nextcloud/ /storage/nextcloud/
#   7. Make THREE changes below (search for "MIGRATION"):
#      a) Uncomment: datadir = "${config.bulkStorage.path}/nextcloud";
#      b) Uncomment: "${config.bulkStorage.path}/nextcloud" in restoreItems
#      c) Comment out: "/var/lib/${app}" in restoreItems (no longer needed)
#   8. sudo nixos-rebuild switch --flake .#aspen
#   9. sudo nextcloud-occ files:scan --all
#  10. sudo nextcloud-occ maintenance:mode --off
#  11. Test web interface, verify files accessible
#  12. After 1-2 weeks: sudo rm -rf /var/lib/nextcloud.backup-*
# ============================================================================

{
  self,
  config,
  configVars,
  lib,
  pkgs,
  nixServiceRecoveryScript,
  ...
}: 

let
  app = "nextcloud"; # first-time install will fail, must delete /var/lib/nextcloud/config/config.php file and rebuild then should work
  recoveryPlan = {
    restoreItems = [
      "/var/lib/${app}"  # MIGRATION: After moving to bulk storage, this path will be mostly empty
                         # When uncommenting the datadir option below, also uncomment the bulk storage path
                         # and comment out this line to avoid backing up an empty directory
      "/var/lib/redis-${app}"  # Redis cache stays on NVMe (separate service, unaffected by datadir)
      "/var/backup/postgresql/${app}.sql.gz"  # Database backup stays on NVMe (separate service)
      #"${config.bulkStorage.path}/nextcloud"  # MIGRATION: Uncomment to backup all Nextcloud state after migration
    ];
    db = {
      type = "postgresql";
      user = "${app}";
      name = "${app}";
      dump = "/var/backup/postgresql/${app}.sql.gz";
    };
    stopServices = [ ]; # nextcloud has no services to stop
    startServices = [ ]; # nextcloud has no services to start
  };
  recoverScript = nixServiceRecoveryScript {
    serviceName = app;
    recoveryPlan = recoveryPlan;
    dbType = recoveryPlan.db.type;
    preRestoreHook = ''
      echo "Activating nextcloud maintenance mode ..."
      ${lib.getExe config.services.nextcloud.occ} maintenance:mode --on || exit 1
    '';
    postRestoreHook = ''
      echo "Deactivating nextcloud maintenance mode ..."
        ${lib.getExe config.services.nextcloud.occ} maintenance:mode --off || exit 1
    '';
  };

in

{

  environment.systemPackages = with pkgs; [ recoverScript ];
  
  sops = {
    secrets = {
      nextcloudAdminPasswd = {
        owner = "${config.users.users.${app}.name}";
        group = "${config.users.users.${app}.group}";
        mode = "0440";
      };
    };
  };

  systemd.services = {
    "${app}-setup" = {
      requires = [ "postgresql.target" ];
      after = [ "postgresql.target" ];
    };
  };

  backups.serviceHooks = {
    preHook = lib.mkMerge [
      (lib.mkOrder 500 [ # runs earlier than other service backup preHook hooks
        "${lib.getExe config.services.nextcloud.occ} maintenance:mode --on || exit 1"
      ])
      (lib.mkAfter [
        "systemctl start postgresqlBackup-${app}.service"
      ])
    ];
    postHook = lib.mkOrder 500 [ # runs earlier than other service backup postHook hooks
      "${lib.getExe config.services.nextcloud.occ} maintenance:mode --off || exit 1"
    ];
  };

  services = {

    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."nextcloud.${configVars.domain1}".listen = [{addr = "127.0.0.1"; port = 4411;}];
    };

    ${app} = {
      enable = true;
      hostName = "nextcloud.${configVars.domain1}";
      package = pkgs.nextcloud32; # manually increment with upgrades

      # MIGRATION: Move entire Nextcloud state from NVMe to bulk storage HDD/ZFS pool
      # Uncomment after rsyncing /var/lib/nextcloud/ to /storage/nextcloud/
      # This moves ALL state (config, apps, user data) to bulk storage
      #datadir = "${config.bulkStorage.path}/nextcloud";

      database.createLocally = false; # enables postgres service if true, manual setup below
      configureRedis = true; # creates redis instance
      caching.redis = true; # load redis into nextcloud php
      maxUploadSize = "30G"; # max upload size
      https = true;
      autoUpdateApps.enable = true;
      extraAppsEnable = true;
      extraApps = {
        inherit (config.services.nextcloud.package.packages.apps) contacts calendar tasks mail;
        #oidc_login = pkgs.fetchNextcloudApp {
        #  sha256 = "sha256-DrbaKENMz2QJfbDKCMrNGEZYpUEvtcsiqw9WnveaPZA=";
        #  url = "https://github.com/pulsejet/nextcloud-oidc-login/releases/download/v3.2.0/oidc_login.tar.gz";
        #  license = "gpl3";
        #};
      };
      settings = {
        defaultapp = "files";
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
        #trashbin_retention_obligation = "auto, 7";
        
        ## openid connect oidc:
        #allow_user_to_change_display_name = false;
        #lost_password_link = "disabled";
        #oidc_login_provider_url = "https://identity.opticon.dev";
        #oidc_login_client_id = "7Au52dmVWwvAGdqvrsLatNjedPoSIfQw~UWRj.M24VWhhlDp8v_tXUtePMvCz9pn~Vt1EVBc";
        #oidc_login_client_secret = "";
        #oidc_login_auto_redirect = false; # bypass Nextcloud login screen and go right to identity provider, need to manually disable in order to access login screen to login as Admin user...
        #oidc_login_end_session_redirect = false; # true setting to cause identity provider logout with nextcloud logout does not currently work...
        #oidc_login_logout_url = "https://identity.opticon.dev"; # just redirect here on nextcloud logout
        #oidc_login_button_text = "Login with Opticon Identify Verification";
        #oidc_login_hide_password_form = false;
        #oidc_login_use_id_token = true;
        #oidc_login_default_group = "oidc";
        #oidc_login_use_external_storage = false;
        #oidc_login_scope = "openid profile email groups";
        #oidc_login_proxy_ldap = false;
        #oidc_login_disable_registration = true;
        #oidc_login_redir_fallback = false;
        #oidc_login_tls_verify = true;
        #oidc_create_groups = false;
        #oidc_login_webdav_enabled = false;
        #oidc_login_password_authentication = false;
        #oidc_login_public_key_caching_time = 86400;
        #oidc_login_min_time_between_jwks_requests = 10;
        #oidc_login_well_known_caching_time = 86400;
        #oidc_login_update_avatar = false;
        #oidc_login_code_challenge_method = "S256";
        #oidc_login_attributes = {
        #  "id" = "preferred_username";
        #  "name" = "name";
        #  "mail" = "email";
        #  "groups" = "groups";
        #};

      };
      config = {
        dbtype = "pgsql";
        dbhost = "/run/postgresql";
        dbname = "${app}";
        dbuser = "${app}";
        adminuser = "${configVars.users.chris.fullName}";
        adminpassFile = "${config.sops.secrets.nextcloudAdminPasswd.path}";
      };
      phpOptions = {
        "opcache.interned_strings_buffer" = "16"; # suggested by nextcloud's health check
      };
    };

    postgresql = {
      ensureDatabases = ["${app}"];
      ensureUsers = [
        {
          name = "${app}";
          ensureDBOwnership = true;
          ensureClauses.createdb = true;
        }
      ];
    };

    postgresqlBackup.databases = [ "${app}" ];

    borgbackup.jobs."${config.networking.hostName}" = {
      readWritePaths = lib.mkAfter [ "/var/lib/${app}/" ]; # needed to allow borgbackup readwrite access to nextcloud directory containing occ command execution (for turning on/off maintenance mode)
      paths = lib.mkAfter recoveryPlan.restoreItems;
    };
  
    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain1}`)";
        service = "${app}";
        middlewares = [
          "nextcloud-headers"
          "nextcloud-redirect-dav"
        ];
        tls = {
          certResolver = "cloudflareDns";
          options = "tls-13@file";
        };
      };
      middlewares = {
        nextcloud-headers = {
          headers = {
            sslRedirect = true;
            accessControlMaxAge = "100";
            stsSeconds = "31536000"; # force browsers to only connect over https
            stsIncludeSubdomains = true; # force browsers to only connect over https
            stsPreload = true; # force browsers to only connect over https
            forceSTSHeader = true; # force browsers to only connect over https
            contentTypeNosniff = true; # sets x-content-type-options header value to "nosniff", reduces risk of drive-by downloads
            #frameDeny = true; # sets x-frame-options header value to "deny", prevents attacker from spoofing website in order to fool users into clicking something that is not there
            customFrameOptionsValue = "SAMEORIGIN"; # suggested by nextcloud, overrides frameDeny
            browserXssFilter = true; # sets x-xss-protection header value to "1; mode=block", which prevents page from loading if detecting a cross-site scripting attack
            contentSecurityPolicy = [ # sets content-security-policy header to suggested value
              "default-src"
              "self"
            ];
            referrerPolicy = "same-origin";
            addVaryHeader = true;
          };
        };
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