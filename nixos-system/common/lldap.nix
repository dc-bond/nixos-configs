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

  sops = {
    secrets = {
      lldapJwtSecret = {};
      lldapLdapUserPasswd = {};
    };
    templates = {
      "${app}-env".content = ''
        LLDAP_JWT_SECRET=${config.sops.placeholder.lldapJwtSecret}
        LLDAP_LDAP_USER_PASS=${config.sops.placeholder.lldapLdapUserPasswd}
      '';
    };
  };

  services = {

    ${app} = {
      enable = true;
      settings = {
        ldap_user_email = "${configVars.userEmail}";
        ldap_user_dn = "admin";
        ldap_port = 3890;
        ldap_base_dn = "dc=${configVars.domain1Short},dc=com";
        http_url = "https://lldap.${configVars.domain1}";
        http_port = 17170;
        http_host = "127.0.0.1";
        database_url = "postgres:///${app}";
      };    
      environmentFile = config.sops.templates."${app}-env".path;
    };

    postgresql = {
      ensureDatabases = [ "${app}" ];
      ensureUsers = [
        {
          name = "${app}";
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };

    postgresqlBackup = {
      databases = [ "${app}" ];
    };

    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain1}`)";
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