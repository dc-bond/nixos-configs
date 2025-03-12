{ 
pkgs,
config,
configVars, 
lib,
... 
}: 

let
  app = "graylog";
in

{

  networking.firewall.allowedUDPPorts = [ 12201 ];

  sops.secrets = {
    graylogPasswdSecret = {
      owner = config.users.users."${app}".name;
      group = config.users.users."${app}".group;
      mode = "0440";
    };
    graylogRootPasswdSha2 = {
      owner = config.users.users."${app}".name;
      group = config.users.users."${app}".group;
      mode = "0440";
    };
    graylogUserEmailPasswd = {
      owner = config.users.users."${app}".name;
      group = config.users.users."${app}".group;
      mode = "0440";
    };
  };

  systemd.services.graylog = {
    environment = {
      GRAYLOG_PASSWORD_SECRET = "${config.sops.secrets.graylogPasswdSecret.path}";
      GRAYLOG_ROOT_PASSWORD_SHA2 = "${config.sops.secrets.graylogRootPasswdSha2.path}";
      GRAYLOG_USER_EMAIL_PASSWORD = "${config.sops.secrets.graylogUserEmailPasswd.path}";
    };
  };

  services = {

    ${app} = {
      enable = true;
      passwordSecret = "$GRAYLOG_PASSWORD_SECRET";
      rootPasswordSha2 = "$GRAYLOG_ROOT_PASSWORD_SHA2";
      rootUsername = "${configVars.userEmail}";
      extraConfig = ''
        http_external_uri = https://${app}.${configVars.domain2}/
        java.net.preferIPv4Stack = true
        root_timezone = America/New_York
        root_email = ${configVars.userEmail}
        allow_highlighting = true
        transport_email_enabled = true
        transport_email_hostname = ssl://mail.privateemail.com
        transport_email_port = 465
        transport_email_use_tls = false
        transport_email_use_ssl = true
        transport_email_use_auth = true
        transport_email_auth_username = ${configVars.userEmail}
        transport_email_auth_password = $GRAYLOG_USER_EMAIL_PASSWORD
        transport_email_socket_connection_timeout = 30s
        transport_email_socket_timeout = 30s
      '';
        #transport_email_from_email = graylog@${configVars.domain1}
        #transport_email_web_interface_url = https://${app}.${configVars.domain2}
      elasticsearchHosts = [ "http://127.0.0.1:9200" ];
    };
    mongodb = {
      enable = true;
      package = pkgs.mongodb-ce;
    };
    opensearch = {
      enable = true;
      settings = {
        "cluster.name" = "graylog";
        "search.max_aggregation_rewrite_filters" = "0";
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [ "secure-headers" ];
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
            url = "http://127.0.0.1:9000";
          }
          ];
        };
      };
    };

  };

}