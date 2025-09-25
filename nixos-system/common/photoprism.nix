{
  pkgs,
  config,
  lib,
  configVars,
  ...
}: 

let

  app = "photoprism";
  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";
  recoveryPlan = {
    serviceName = "${app}";
    localRestoreRepoPath = "${config.backups.borgDir}/${config.networking.hostName}";
    cloudRestoreRepoPath = "${config.backups.borgCloudDir}/${config.networking.hostName}";
    restoreItems = [
      "/var/lib/private/${app}"
      "/var/backup/mysql/${app}.gz"
    ];
    db = {
      user = "${app}";
      name = "${app}";
      dump = "/var/backup/mysql/${app}.gz";
    };
    stopServices = [ "${app}" ];
    startServices = [ "${app}" ];
  };
  recoverPhotoprismScript = pkgs.writeShellScriptBin "recoverPhotoprism" ''
    #!/bin/bash
   
    # track errors
    set -euo pipefail

    # set borg passphrase environment variable
    export BORG_PASSPHRASE=$(cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

    # repo selection
    read -p "Use cloud repo? (y/N): " use_cloud
    if [[ "$use_cloud" =~ ^[Yy]$ ]]; then
      REPO="${recoveryPlan.cloudRestoreRepoPath}"
      echo "Using cloud repo"
    else
      REPO="${recoveryPlan.localRestoreRepoPath}"
      echo "Using local repo"
    fi

    # archive selection
    echo "Available archives at $REPO:"
    echo ""
    archives=$(${pkgs.borgbackup}/bin/borg list --short "$REPO")
    echo "$archives" | nl -w2 -s') '
    echo ""
    read -p "Enter number: " num
    ARCHIVE=$(echo "$archives" | sed -n "''${num}p")
    if [ -z "$ARCHIVE" ]; then
      echo "Invalid selection"
      exit 1
    fi
    echo "Selected: $ARCHIVE"

    # stop services
    for svc in ${lib.concatStringsSep " " recoveryPlan.stopServices}; do
      echo "Stopping $svc ..."
      systemctl stop "$svc" || true
    done

    # extract data from archive and overwrite existing data
    cd /
    echo "Extracting data from $REPO::$ARCHIVE ..."
    ${pkgs.borgbackup}/bin/borg extract --verbose --list "$REPO"::"$ARCHIVE" ${lib.concatStringsSep " " recoveryPlan.restoreItems}
    
    # drop and recreate database
    echo "Dropping and recreating clean database ${recoveryPlan.db.name} ..."
    sudo -u mysql mysql -e "DROP DATABASE IF EXISTS ${recoveryPlan.db.name};"
    sudo -u mysql mysql -e "CREATE DATABASE ${recoveryPlan.db.name};"
    sudo -u mysql mysql -e "GRANT ALL PRIVILEGES ON ${recoveryPlan.db.name}.* TO '${recoveryPlan.db.user}'@'localhost';"
    
    # restore database from dump backup
    echo "Restoring database from ${recoveryPlan.db.dump} ..."
    gunzip -c ${recoveryPlan.db.dump} | sudo -u mysql mysql ${recoveryPlan.db.name}

    # start services
    for svc in ${lib.concatStringsSep " " recoveryPlan.startServices}; do
      echo "Starting $svc ..."
      systemctl start "$svc" || true
    done

    echo "Recovery complete!"
  '';

in

{
  
  sops.secrets = {
    photoprismAdminPasswd = {};
    borgCryptPasswd = {};
  };

  environment.systemPackages = with pkgs; [ recoverPhotoprismScript ];

  systemd.services."${app}" = {
    requires = [ "mysql.service" ];
    after = [ "mysql.service" ];
  };

  backups.serviceHooks = {
    preStop = lib.mkAfter [
      "systemctl stop ${app}.service"
      "sleep 2"
      "systemctl start mysql-backup.service"
    ];
    postStart = lib.mkAfter [
      "systemctl start ${app}.service"
    ];
  };

  services = {

    ${app} = {
      enable = true;
      address = "127.0.0.1";
      originalsPath = "${config.drives.storageDrive1}/media/family-media";
      passwordFile = "${config.sops.secrets.photoprismAdminPasswd.path}";
      settings = {
        PHOTOPRISM_AUTH_MODE = "password";                                                      # authentication mode (public, password)
        PHOTOPRISM_SITE_URL = "https://photos.${configVars.domain2}/";                          # public server URL incl http:// or https:// and /path, :port is optional
        PHOTOPRISM_ORIGINALS_LIMIT = "20000";                                                   # file size limit for originals in MB (increase for high-res video)
        PHOTOPRISM_HTTP_COMPRESSION = "gzip";                                                   # improves transfer speed and bandwidth utilization (none or gzip)
        PHOTOPRISM_LOG_LEVEL = "info";                                                          # log level: trace, debug, info, warning, error, fatal, or panic
        PHOTOPRISM_READONLY = "false";                                                          # do not modify originals directory (reduced functionality)
        PHOTOPRISM_EXPERIMENTAL = "false";                                                      # enables experimental features
        PHOTOPRISM_DISABLE_CHOWN = "false";                                                     # disables updating storage permissions via chmod and chown on startup
        PHOTOPRISM_DISABLE_WEBDAV = "false";                                                    # disables built-in WebDAV server
        PHOTOPRISM_DISABLE_SETTINGS = "false";                                                  # disables settings UI and API
        PHOTOPRISM_DISABLE_TENSORFLOW = "true";                                                 # disables all features depending on TensorFlow
        PHOTOPRISM_DISABLE_FACES = "true";                                                      # disables face detection and recognition (requires TensorFlow)
        PHOTOPRISM_DISABLE_CLASSIFICATION = "true";                                             # disables image classification (requires TensorFlow)
        PHOTOPRISM_DISABLE_RAW = "false";                                                       # disables indexing and conversion of RAW files
        PHOTOPRISM_RAW_PRESETS = "false";                                                       # enables applying user presets when converting RAW files (reduces performance)
        PHOTOPRISM_JPEG_QUALITY = "30";                                                         # a higher value increases the quality and file size of JPEG images and thumbnails (25-100)
        PHOTOPRISM_DETECT_NSFW = "false";                                                       # automatically flags photos as private that MAY be offensive (requires TensorFlow)
        PHOTOPRISM_UPLOAD_NSFW = "true";                                                        # allows uploads that MAY be offensive (no effect without TensorFlow)
        PHOTOPRISM_DATABASE_DRIVER = "mysql";                                                   # use MariaDB 10.5+ or MySQL 8+ instead of SQLite for improved performance
        PHOTOPRISM_DATABASE_SERVER = "/run/mysqld/mysqld.sock";                                 # MariaDB or MySQL database server (hostname:port)
        PHOTOPRISM_DATABASE_NAME = "${app}";                                                    # MariaDB or MySQL database schema name
        PHOTOPRISM_DATABASE_USER = "${app}";                                                    # MariaDB or MySQL database user name
        PHOTOPRISM_SITE_CAPTION = "${configVars.userLastName} Private Family Photo and Video Server";
        PHOTOPRISM_SITE_DESCRIPTION = "${configVars.userLastName} Family Photos and Videos";
        PHOTOPRISM_SITE_AUTHOR = "${configVars.userFullName}";
        NVIDIA_VISIBLE_DEVICES = "all";
        PHOTOPRISM_INDEX_SCHEDULE = "";
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

    borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;
    
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