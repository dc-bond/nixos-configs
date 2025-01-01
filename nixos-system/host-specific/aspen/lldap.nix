{
  pkgs,
  lib,
  config,
  configVars,
  ...
}: 

let
  app = "lldap";
in

{

  sops.secrets = {
    lldapJwtSecret = {};
    lldapLdapUserPasswd = {};
  };

  services = {

    ${app} = {
      enable = true;
      settings = {
        lldap_user_email = "${configVars.userEmail}";
        lldap_user_dn = "admin";
        lldap_port = 3890;
        lldap_base_dn = "dc=${configVars.domain2Short},dc=dev";
        lldap_http_url = "http://127.0.0.1";
        lldap_http_port = 17170;
        database_url = "postgresql://@/${app}";
      };    
      environment = {
        LLDAP_JWT_SECRET_FILE=${config.sops.placeholder.lldapJwtSecret};
        LLDAP_LDAP_USER_PASS_FILE=${config.sops.placeholder.lldapLdapUserPasswd};
      };
    };

    postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
      ensureDatabases = [ "${app}" ];
      ensureUsers = [
        {
          name = "${app}"; # lldap user on host must have access
          ensureDBOwnership = true;
        }
      ];
    };

    postgresqlBackup = { # postgres database backup
      enable = true;
      databases = [ "${app}" ];
      startAt = "*-*-* 01:00:00"; # daily starting at 1:00am
    };

    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [
          #"authelia"
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
            url = "http://127.0.0.1:17170";
          }
          ];
        };
      };
    };

  };

}