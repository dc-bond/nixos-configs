{
  config,
  lib,
  configLib,
  configVars,
  pkgs,
  inputs,
  nixServiceRecoveryScript,
  ...
}: 

let

  app = "home-assistant";
  recoveryPlan = {
    restoreItems = [
      "/var/lib/hass"
      "/var/lib/mosquitto"
      "/var/backup/postgresql/hass.sql.gz"
    ];
    db = {
      type = "postgresql";
      user = "hass";
      name = "hass";
      dump = "/var/backup/postgresql/hass.sql.gz";
    };
    stopServices = [ "${app}" "mosquitto" ];
    startServices = [ "mosquitto" "${app}" ];
  };
  recoverScript = nixServiceRecoveryScript {
    serviceName = app;
    recoveryPlan = recoveryPlan;
    dbType = recoveryPlan.db.type;
  };

in

{

  imports = [
    inputs.private.nixosModules.home-assistant-automations
  ];

  sops = {
    secrets = {
      mqttHassPasswd = {};
      chrisEmailPasswd = {};
      familyNotificationsWebhookUrl = {};
    };
    templates = {
      "hass-secrets" = {
        content = ''
          notifySenderEmail: ${configVars.users.chris.email}
          notifySenderAlias: ${configVars.users.chris.email}
          notifyDefaultRecipient: ${configVars.users.chris.email}
          notifyEmailServer: ${configVars.mailservers.namecheap.smtpHost}
          notifyEmailUsername: ${configVars.users.chris.email}
          notifyEmailPasswd: ${config.sops.placeholder.chrisEmailPasswd}
          notifyEmailPort: ${toString configVars.mailservers.namecheap.smtpPort}
          familyNotificationsWebhookUrl: ${config.sops.placeholder.familyNotificationsWebhookUrl}
        '';
        path = "/var/lib/hass/secrets.yaml";
        owner = "${config.users.users.hass.name}";
        group = "${config.users.users.hass.group}";
        mode = "0440";
      };
    };
  };

  environment.systemPackages = with pkgs; [ recoverScript ];

  systemd.services."${app}" = {
    requires = [ "postgresql.target" ];
    after = [ "postgresql.target" ];
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
        "automation ui" = "!include automations.yaml";
        #"automation nixos" defined in private repo via inputs.private.nixosModules.home-assistant-automations, merged in with ui-generated automations
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
          encryption = "starttls"; # for port 587
          #encryption = "tls"; # for port 465
        };
        rest_command = {
          matrix_notify = {
            url = "!secret familyNotificationsWebhookUrl";
            method = "POST";
            content_type = "application/json";
            payload = ''
              {
                "text": "{{ message }}",
                "msgtype": "m.text"
              }
            '';
          };
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