{
  pkgs,
  config,
  lib,
  configVars,
  nixServiceRecoveryScript,
  ...
}:

let

  app = "photoprism";
  recoveryPlan = {
    restoreItems = [
      "/var/lib/private/${app}"
      "/var/backup/mysql/${app}.gz"
    ];
    db = {
      type = "mysql";
      user = "${app}";
      name = "${app}";
      dump = "/var/backup/mysql/${app}.gz";
    };
    stopServices = [ "${app}" ];
    startServices = [ "${app}" ];
  };
  recoverScript = nixServiceRecoveryScript {
    serviceName = app;
    recoveryPlan = recoveryPlan;
    dbType = recoveryPlan.db.type;
    preSvcStartHook = ''
      echo "Recreating cache directory with correct permissions..."
      mkdir -p /var/lib/private/${app}/cache
      chown -R photoprism:photoprism /var/lib/private/${app}
    '';
  };

in

{
  
  sops.secrets = {
    photoprismAdminPasswd = {};
  };

  environment.systemPackages = with pkgs; [ 
    recoverScript
    vips # for using vips to generate thumbnails
  ];

  systemd.services."${app}" = {
    requires = [ "mysql.service" ];
    after = [ "mysql.service" ];
  };

  #serviceHealth.${app} = {
  #  enable = true;
  #  checkCommand = "${pkgs.curl}/bin/curl -f http://127.0.0.1:2342/api/v1/status";
  #  checkInterval = "5min";
  #  initialDelay = "2min"; # give photoprism time to start up after boot
  #};

  backups.serviceHooks = {
    preHook = lib.mkAfter [
      "systemctl stop ${app}.service"
      "sleep 2"
      "systemctl start mysql-backup.service"
    ];
    postHook = lib.mkAfter [
      "systemctl start ${app}.service"
    ];
  };

  services = {

    ${app} = {
      enable = true;
      address = "127.0.0.1";
      originalsPath = "${config.bulkStorage.path}/media/family-media";
      passwordFile = "${config.sops.secrets.photoprismAdminPasswd.path}";
      settings = {
        PHOTOPRISM_AUTH_MODE = "public";                                                        # authentication mode (public, password)
        PHOTOPRISM_SITE_URL = "https://photos.${configVars.domain2}/";                          # public server URL incl http:// or https:// and /path, :port is optional
        PHOTOPRISM_IMPORT_PATH = "/var/lib/photoprism/import";                                  # absolute path for systemd ReadWritePaths hardening
        PHOTOPRISM_ORIGINALS_LIMIT = "50000";                                                   # file size limit for originals in MB (increase for high-res video)
        PHOTOPRISM_HTTP_COMPRESSION = "gzip";                                                   # improves transfer speed and bandwidth utilization (none or gzip)
        PHOTOPRISM_LOG_LEVEL = "info";                                                          # log level: trace, debug, info, warning, error, fatal, or panic
        PHOTOPRISM_READONLY = "false";                                                          # do not modify originals directory (reduced functionality)
        PHOTOPRISM_EXPERIMENTAL = "false";                                                      # enables experimental features
        PHOTOPRISM_DISABLE_CHOWN = "true";                                                      # disables updating storage permissions via chmod and chown on startup (manually set)
        PHOTOPRISM_DISABLE_WEBDAV = "false";                                                    # disables built-in WebDAV server
        PHOTOPRISM_DISABLE_SETTINGS = "true";                                                   # disables settings UI and API in "public" auth mode
        PHOTOPRISM_DISABLE_TENSORFLOW = "true";                                                 # disables all features depending on TensorFlow
        PHOTOPRISM_DISABLE_RAWTHERAPEE = "true";
        PHOTOPRISM_DISABLE_DARKTABLE = "true";
        PHOTOPRISM_DISABLE_IMAGEMAGICK = "true";
        PHOTOPRISM_DISABLE_FACES = "true";                                                      # disables face detection and recognition (requires TensorFlow)
        PHOTOPRISM_DISABLE_CLASSIFICATION = "true";                                             # disables image classification (requires TensorFlow)
        PHOTOPRISM_DISABLE_RAW = "false";                                                       # disables indexing and conversion of RAW files
        PHOTOPRISM_RAW_PRESETS = "false";                                                       # enables applying user presets when converting RAW files (reduces performance)
        PHOTOPRISM_JPEG_QUALITY = "95";                                                         # a higher value increases the quality and file size of JPEG images and thumbnails (25-100)
        #PHOTOPRISM_JPEG_SIZE = "2560";                                                         # size of JPEG when converting from RAW
        #PHOTOPRISM_PNG_SIZE = "2560";                                                          # size of PNG when converting from RAW
        PHOTOPRISM_THUMB_UNCACHED = "true";                                                     # dynamically generates thumbs while scrolling through library
        PHOTOPRISM_THUMB_SIZE_UNCACHED = "2560";
        #PHOTOPRISM_THUMB_SIZE = "2560";                                                        # used when THUMB_UNCACHED is set to false; pre-generates thumbs at this pixel density
        PHOTOPRISM_THUMB_FILTER = "blackman";
        PHOTOPRISM_THUMB_COLOR = "srgb";
        PHOTOPRISM_THUMB_LIBRARY = "vips";
        PHOTOPRISM_DETECT_NSFW = "false";                                                       # automatically flags photos as private that MAY be offensive (requires TensorFlow)
        PHOTOPRISM_UPLOAD_NSFW = "true";                                                        # allows uploads that MAY be offensive (no effect without TensorFlow)
        PHOTOPRISM_DATABASE_DRIVER = "mysql";                                                   # use MariaDB 10.5+ or MySQL 8+ instead of SQLite for improved performance
        PHOTOPRISM_DATABASE_SERVER = "/run/mysqld/mysqld.sock";                                 # MariaDB or MySQL database server (hostname:port)
        PHOTOPRISM_DATABASE_NAME = "${app}";                                                    # MariaDB or MySQL database schema name
        PHOTOPRISM_DATABASE_USER = "${app}";                                                    # MariaDB or MySQL database user name
        PHOTOPRISM_SITE_CAPTION = "Bond Private Family Photo and Video Server";
        PHOTOPRISM_SITE_DESCRIPTION = "Bond Family Photos and Videos";
        PHOTOPRISM_SITE_AUTHOR = "${configVars.users.chris.fullName}";
        NVIDIA_VISIBLE_DEVICES = "all";
        PHOTOPRISM_INDEX_SCHEDULE = "0 6 * * *";                                                # auto-index daily at 6am
      };
    };

    mysql = {
      ensureDatabases = ["${app}"];
      ensureUsers = [
        {
          name = "${app}";
          ensurePermissions = { "${app}.*" = "ALL PRIVILEGES"; };
        }
      ];
    };

    mysqlBackup = { databases = [ "${app}" ]; };

    borgbackup.jobs."${config.networking.hostName}" = {
      paths = lib.mkAfter recoveryPlan.restoreItems;
      exclude = [ "/var/lib/private/${app}/cache" ]; # exclude cache which is regenerated dynamically
    };
    
    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`photos.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [
          "secure-headers"
          "trusted-allow"
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
            url = "http://127.0.0.1:2342";
          }
          ];
        };
      };
    };

  };

}