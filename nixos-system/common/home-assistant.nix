{ 
  config,
  lib,
  configLib,
  configVars,
  pkgs, 
  ... 
}: 

let
  app = "home-assistant";
  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";
  recoveryPlan = {
    serviceName = "${app}";
    localRestoreRepoPath = "${config.backups.borgDir}/${config.networking.hostName}";
    cloudRestoreRepoPath = "${config.backups.borgCloudDir}/${config.networking.hostName}";
    restoreItems = [
      "/var/lib/hass"
      "/var/lib/mosquitto"
      "/var/backup/postgresql/hass.sql.gz"
    ];
    db = {
      user = "hass";
      name = "hass";
      dump = "/var/backup/postgresql/hass.sql.gz";
    };
    stopServices = [ "${app}" "mosquitto" ];
    startServices = [ "mosquitto" "${app}" ];
  };
  recoverHassScript = pkgs.writeShellScriptBin "recoverHass" ''
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
    su - postgres -c "dropdb --if-exists ${recoveryPlan.db.name}"
    su - postgres -c "createdb -O ${recoveryPlan.db.user} ${recoveryPlan.db.name}"
    
    # restore database from dump backup
    echo "Restoring database from ${recoveryPlan.db.dump} ..."
    gunzip -c ${recoveryPlan.db.dump} | su - postgres -c "psql ${recoveryPlan.db.name}"

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
    borgCryptPasswd = {};
    mqttHassPasswd = {};
    hassSecrets = {
      owner = "hass";
      path = "/var/lib/hass/secrets.yaml";
    };
  };

  environment.systemPackages = with pkgs; [ recoverHassScript ];

  systemd.services."${app}" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };
  
  backups.serviceHooks = {
    preHook = lib.mkAfter [
      "systemctl stop ${app}.service"
      "systemctl stop mosquitto.service"
      "sleep 2"
      "systemctl start postgresqlBackup-hass.service"
    ];
    postHook = lib.mkAfter [
      "systemctl start mosquitto.service"
      "systemctl start ${app}.service"
    ];
  };

  services = {

    ${app} = {
      enable = true;
      package = (pkgs.home-assistant.override {
        extraPackages = py: with py; [ psycopg2 ];
        }).overrideAttrs (oldAttrs: {
          doInstallCheck = false;
        });
      extraComponents = [
        "default_config"
        "mqtt"
        "zwave_js"
        "hue"
        "mobile_app"
        "notify"
        "smtp"
      ];
      config = {
        http = {
          server_port = 8123;
          use_x_forwarded_for = true;
          trusted_proxies = [
            "127.0.0.1"
          ];
        };
        recorder.db_url = "postgresql://@/hass";
        automation = "!include automations.yaml";
        mobile_app = "";
        notify = {
          name = "email";
          platform = "smtp";
          sender = "!secret notifySenderEmail";
          sender_name = "!secret notifySenderAlias";
          recipient = [ "!secret notifyDefaultRecipient" ];
          server = "!secret notifyEmailServer";
          port = "!secret notifyEmailPort";
          timeout = 60;
          username = "!secret notifyEmailUsername";
          password = "!secret notifyEmailPasswd";
          #encryption = "starttls";
          encryption = "tls";
        };
      };
    };
    
    mosquitto = {
      enable = true;
      logType = [ "error" ];
      logDest = [ "syslog" ];
      listeners = [
        {
          users.hass = {
            acl = [ "readwrite #" ];
            passwordFile = "${config.sops.secrets.mqttHassPasswd.path}";
          };
        }
      ];
    };

    postgresql = {
      ensureDatabases = [ "hass" ];
      ensureUsers = [
        {
          name = "hass";
          ensureDBOwnership = true;
        }
      ];
    };

    postgresqlBackup.databases = [ "hass" ];
    
    borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;
    
    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [
          #"authelia" # ios app does not support authentication provider sittnig in front of home assistant
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
            url = "http://127.0.0.1:8123";
          }
          ];
        };
      };
    };

  };

}