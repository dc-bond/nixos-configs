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
        ldap_base_dn = "dc=${configVars.domain2Short},dc=dev";
        http_url = "https://lldap.${configVars.domain2}";
        http_port = 17170;
        http_host = "127.0.0.1";
        database_url = "postgres:///${app}";
      };    
      environmentFile = config.sops.templates."${app}-env".path;
    };

    postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
      ensureDatabases = [ "${app}" ];
      ensureUsers = [
        {
          name = "${app}"; # lldap user on host must have access
          ensureDBOwnership = true;
          ensureClauses.login = true;
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
        rule = "Host(`${app}-test.${configVars.domain2}`)";
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