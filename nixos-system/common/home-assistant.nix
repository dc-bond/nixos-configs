{ 
  config,
  configLib,
  pkgs, 
  ... 
}: 

{

  #networking.firewall.allowedTCPPorts = [ 8123 ];

  sops.secrets.hassSecrets = {
    owner = "hass";
    path = "/var/lib/hass/secrets.yaml";
  };

  services = {

    home-assistant = {
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
        http.server_port = 8123;
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
          port = "! secret notifyEmailPort";
          timeout = 60;
          username = "!secret notifyEmailUsername";
          password = "!secret notifyEmailPasswd";
          encryption = "starttls";
        };
      };
    };

    postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
      ensureDatabases = [ "hass" ];
      ensureUsers = [
        {
          name = "hass"; # hass user on host must have access
          ensureDBOwnership = true;
        }
      ];
    };

    postgresqlBackup = { # postgres database backup
      enable = true;
      databases = [ "hass" ];
      startAt = "*-*-* 01:00:00"; # daily starting at 1:00am
    };

  };

}