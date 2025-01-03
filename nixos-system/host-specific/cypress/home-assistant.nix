{ 
  config,
  configLib,
  configVars,
  pkgs, 
  ... 
}: 

let
  app = "home-assistant";
in

{

  sops.secrets.hassSecrets = {
    owner = "hass";
    path = "/var/lib/hass/secrets.yaml";
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
          recipient = [ 
            "!secret notifyDefaultRecipient"
          ];
          server = "!secret notifyEmailServer";
          port = "!secret notifyEmailPort";
          timeout = 60;
          username = "!secret notifyEmailUsername";
          password = "!secret notifyEmailPasswd";
          encryption = "starttls";
        };
      };
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

    postgresqlBackup = {
      databases = [ "hass" ];
    };
    
    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [
          #"authelia" # ios app does not support authentication provider sittnig in front of home assistant
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