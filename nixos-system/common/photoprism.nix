{
  pkgs,
  config,
  configVars,
  ...
}: 

let

  app = "photoprism";

in

{

  sops = {
    secrets = {
      photoprismAdminPasswd = {
        owner = "${config.users.users.${app}.name}";
        group = "${config.users.users.${app}.group}";
        mode = "0440";
      };
    };
  };

  services = {

    ${app} = {
      enable = true;
      address = "127.0.0.1";
      originalsPath = "${config.drives.storageDrive1}/family-photos-videos";
      importPath = "photoprism-import";
      passwordFile = "${config.sops.secrets.photoprismAdminPasswd.path}";
      settings = {
        PHOTOPRISM_AUTH_MODE = "password";                                                      # authentication mode (public, password)
        PHOTOPRISM_SITE_URL = "https://${app}.${configVars.domain2}/";                          # public server URL incl http:// or https:// and /path, :port is optional
        PHOTOPRISM_ORIGINALS_LIMIT = 20000;                                                     # file size limit for originals in MB (increase for high-res video)
        PHOTOPRISM_HTTP_COMPRESSION = "gzip";                                                   # improves transfer speed and bandwidth utilization (none or gzip)
        PHOTOPRISM_LOG_LEVEL = "info";                                                          # log level: trace, debug, info, warning, error, fatal, or panic
        PHOTOPRISM_READONLY = "false";                                                          # do not modify originals directory (reduced functionality)
        PHOTOPRISM_EXPERIMENTAL = "false";                                                      # enables experimental features
        PHOTOPRISM_DISABLE_CHOWN = "false";                                                     # disables updating storage permissions via chmod and chown on startup
        PHOTOPRISM_DISABLE_WEBDAV = "false";                                                    # disables built-in WebDAV server
        PHOTOPRISM_DISABLE_SETTINGS = "false";                                                  # disables settings UI and API
        PHOTOPRISM_DISABLE_TENSORFLOW = "false";                                                # disables all features depending on TensorFlow
        PHOTOPRISM_DISABLE_FACES = "false";                                                     # disables face detection and recognition (requires TensorFlow)
        PHOTOPRISM_DISABLE_CLASSIFICATION = "false";                                            # disables image classification (requires TensorFlow)
        PHOTOPRISM_DISABLE_RAW = "false";                                                       # disables indexing and conversion of RAW files
        PHOTOPRISM_RAW_PRESETS = "false";                                                       # enables applying user presets when converting RAW files (reduces performance)
        PHOTOPRISM_JPEG_QUALITY = 85;                                                           # a higher value increases the quality and file size of JPEG images and thumbnails (25-100)
        PHOTOPRISM_DETECT_NSFW = "false";                                                       # automatically flags photos as private that MAY be offensive (requires TensorFlow)
        PHOTOPRISM_UPLOAD_NSFW = "true";                                                        # allows uploads that MAY be offensive (no effect without TensorFlow)
        PHOTOPRISM_DATABASE_DRIVER = "mysql";                                                   # use MariaDB 10.5+ or MySQL 8+ instead of SQLite for improved performance
        PHOTOPRISM_DATABASE_SERVER = "photoprism-mariadb:3306";                                 # MariaDB or MySQL database server (hostname:port)
        PHOTOPRISM_DATABASE_NAME = "";      # MariaDB or MySQL database schema name
        PHOTOPRISM_DATABASE_USER: "";      # MariaDB or MySQL database user name
        PHOTOPRISM_DATABASE_PASSWORD = "";  # MariaDB or MySQL database user password
        PHOTOPRISM_SITE_CAPTION = "Bond Private Photo Server";
        PHOTOPRISM_SITE_DESCRIPTION = "Bond Photos";
        PHOTOPRISM_SITE_AUTHOR = "Chris Bond";
        #NVIDIA_VISIBLE_DEVICES = "all";
      };
    };

    mysql = {
      ensureDatabases = ["${app}"];
      ensureUsers = [
        {
          name = "${app}";
          #ensureDBOwnership = true;
          #ensureClauses.createdb = true;
        }
      ];
    };

    mysqlBackup = {
      databases = ["${app}"];
    };

    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [
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
            url = "http://127.0.0.1:2342";
          }
          ];
        };
      };
    };

  };

}