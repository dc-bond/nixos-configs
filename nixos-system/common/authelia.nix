{ 
  config, 
  pkgs, 
  configVars,
  ... 
}:

let
  app = "authelia";
in

{

  sops.secrets = {
    autheliaLdapUserPasswd = {
      owner = config.users.users."${app}-3".name;
      group = config.users.users."${app}-3".group;
      mode = "0440";
    };
    autheliaJwtSecret = {
      owner = config.users.users."${app}-3".name;
      group = config.users.users."${app}-3".group;
      mode = "0440";
    };
    autheliaStorageEncryptionKey = {
      owner = config.users.users."${app}-3".name;
      group = config.users.users."${app}-3".group;
      mode = "0440";
    };
    autheliaSessionSecret = {
      owner = config.users.users."${app}-3".name;
      group = config.users.users."${app}-3".group;
      mode = "0440";
    };
    #autheliaOidcHmacSecret = {
    #  owner = config.users.users."${app}-3".name;
    #  group = config.users.users."${app}-3".group;
    #  mode = "0440";
    #};
    #autheliaOidcIssuerPrivateKey = {
    #  mode = "0440";
    #};
  };

  services.${app}.instances = {
    "3" = {
      enable = true; 
      settings = {
        theme = "dark";
        default_2fa_method = "webauthn";
        default_redirection_url = "https://${configVars.domain1}/";
        log = {
          level = "debug";
          format = "text"; 
          file_path = "/var/lib/${app}-3/authelia.log";
          keep_stdout = true;
        };
        server = {
          host = "127.0.0.1";
          port = 9091; # automatically opens firewall port
        };
        authentication_backend = {
          refresh_interval = "5m";
          password_reset.disable = true;
          ldap = {
            implementation = "custom";
            url = "ldap://${configVars.lldapIp}:3890";
            timeout = "5s";
            start_tls = false;
            base_dn = "dc=professorbond,dc=com";
            username_attribute = "uid";
            additional_users_dn = "ou=people";
            users_filter = "(&(|({username_attribute}={input})({mail_attribute}={input}))(objectClass=person))"; # allow sign in with username OR email
            additional_groups_dn = "ou=groups";
            groups_filter = "(member={dn})";
            group_name_attribute = "cn";
            mail_attribute = "mail";
            display_name_attribute = "displayName";
            user = "uid=admin,ou=people,dc=professorbond,dc=com"; # admin username, password in env variable below
          };
        };
        access_control = {
          default_policy = "deny";
          rules = [
            #{
            #  domain = ["${configVars.domain1}"];
            #  resources = [
            #    "^/wp-admin.*$"
            #    "^/wp-admin/.*$"
            #  ];
            #  subject = "user:admin";
            #  policy = "two_factor";
            #}
            #{
            #  domain = ["excursion2025.${configVars.domain1}"];# only allow chris@dcbond.com user to authenticate to admin/login subfolders of excursion2025.dcbond.com (ghost admin page)
            #  resources = [
            #    "^/ghost.*$"
            #    "^/ghost/.*$"
            #  ];
            #  subject = "user:admin";
            #  policy = "two_factor";
            #}
            {
              domain = [ # bypass authelia when connecting to authelia itself or when connecting to domain1
                "identity.${configVars.domain3}"
                #"${configVars.domain1}"
              ];
              policy = "bypass";
            }
            {
              domain = [ # allow certain users to authenticate to any of these subdomains
                "uptime-kuma.${configVars.domain3}"
              ];
              subject = "user:admin";
              policy = "one_factor";
            }
            {
              domain = [ # catchall for any remaining subdomains to only allow chris@dcbond.com to authenticate
                "*.${configVars.domain3}"
              ];
              subject = "user:admin";
              policy = "one_factor";
            }
          ];
        };
        session = {
          name = "authelia_session";
          domain = "${configVars.domain3}";
          same_site = "lax";
          expiration = "1h";
          inactivity = "5m";
          remember_me_duration = "24h";
          redis.host = "/run/redis-${app}-3/redis.sock";
        };
        regulation = {
          max_retries = 3;
          find_time = "5m";
          ban_time = "15m";
        };
        storage = {
          local = {
            path = "/var/lib/${app}-3/sqlite3.db";
          };
        };
        #identity_provider = {
        #  oidc = {
        #    clients = "";
        #  };
        #};
        notifier = {
          disable_startup_check = false;
          filesystem = {
            filename = "/var/lib/${app}-3/notifications.txt";
          };
        };
      };
      environmentVariables = {
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = "${config.sops.secrets.autheliaLdapUserPasswd.path}";
      };
      secrets = {
        jwtSecretFile = "${config.sops.secrets.autheliaJwtSecret.path}";
        storageEncryptionKeyFile = "${config.sops.secrets.autheliaStorageEncryptionKey.path}";
        sessionSecretFile = "${config.sops.secrets.autheliaSessionSecret.path}";
        #oidcHmacSecretFile = "${config.sops.secrets.autheliaOidcHmacSecret.path}";
        #oidcIssuerPrivateKeyFile = "${config.sops.secrets.autheliaOidcIssuerPrivateKey.path}";
      };
    };
  }; 

  services.redis.servers."${app}-3" = {
    enable = true;
    user = "${app}-3";   
    port = 0;
    unixSocket = "/run/redis-${app}-3/redis.sock";
    unixSocketPerm = 600;
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.${app} = {
      entrypoints = ["websecure"];
      rule = "Host(`identity.${configVars.domain3}`)";
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
          url = "http://127.0.0.1:9091";
        }
        ];
      };
    };
  };

}