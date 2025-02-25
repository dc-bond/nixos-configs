{
  pkgs,
  lib,
  config,
  configVars,
  ...
}: 

let
  app = "immich";
in

{

  #sops = {
  #  secrets = {
  #    lldapJwtSecret = {};
  #    lldapLdapUserPasswd = {};
  #  };
  #  templates = {
  #    "${app}-env".content = ''
  #      LLDAP_JWT_SECRET=${config.sops.placeholder.lldapJwtSecret}
  #      LLDAP_LDAP_USER_PASS=${config.sops.placeholder.lldapLdapUserPasswd}
  #    '';
  #  };
  #};

  services = {

    ${app} = {
      enable = true;
      redis.enable = true;
      environment = {
        IMMICH_LOG_LEVEL = "verbose";
      };
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
            url = "http://127.0.0.1:2283";
          }
          ];
        };
      };
    };

  };

}