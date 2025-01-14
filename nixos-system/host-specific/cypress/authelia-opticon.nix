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
      #owner = config.users.users."${app}-${configVars.domain2Short}".name;
      #group = config.users.users."${app}-${configVars.domain2Short}".group;
      #mode = "0440";
    };
    autheliaJwtSecret = {
      #owner = config.users.users."${app}-${configVars.domain2Short}".name;
      #group = config.users.users."${app}-${configVars.domain2Short}".group;
      #mode = "0440";
    };
    autheliaStorageEncryptionKey = {
      #owner = config.users.users."${app}-${configVars.domain2Short}".name;
      #group = config.users.users."${app}-${configVars.domain2Short}".group;
      #mode = "0440";
    };
    autheliaSessionSecret = {
      #owner = config.users.users."${app}-${configVars.domain2Short}".name;
      #group = config.users.users."${app}-${configVars.domain2Short}".group;
      #mode = "0440";
    };
    #autheliaOidcHmacSecret = {
    #  owner = config.users.users."${app}-${configVars.domain2Short}".name;
    #  group = config.users.users."${app}-${configVars.domain2Short}".group;
    #  mode = "0440";
    #};
    #autheliaOidcJwksKey = {
    #  owner = config.users.users."${app}-${configVars.domain2Short}".name;
    #  group = config.users.users."${app}-${configVars.domain2Short}".group;
    #  mode = "0440";
    #};
  };

  services = {

    ${app}.instances = {
      "${configVars.domain2Short}" = {
        enable = true; 
        settings = {
          theme = "dark";
          default_2fa_method = "webauthn";
          log = {
            level = "info";
            format = "text"; 
            file_path = "/var/lib/${app}-${configVars.domain2Short}/authelia.log";
            keep_stdout = true;
          };
          server.address = "tcp://:9092";
          session = {
            cookies = [
              {
              domain = "${configVars.domain2}";
              authelia_url = "https://identity.${configVars.domain2}";
              }
            ];
            redis.host = "/run/redis-${app}-${configVars.domain2Short}/redis.sock";
          };
          authentication_backend = {
            refresh_interval = "5m";
            password_reset.disable = true;
            ldap = {
              address = "ldap://127.0.0.1:3890";
              base_dn = "dc=${configVars.domain2Short},dc=dev";
              user = "uid=admin,ou=people,dc=${configVars.domain2Short},dc=dev"; # admin username, password in env variable below
              users_filter = "(&(|({username_attribute}={input})({mail_attribute}={input}))(objectClass=person))"; # allow sign in with username OR email
              groups_filter = "(member={dn})";
            };
          };
          access_control = {
            default_policy = "deny";
            rules = [
              #{
              #  domain = ["cloud.${configVars.domain2}"];# only allow chris@dcbond.com user to authenticate to nextcloud admin/login 
              #  resources = [
              #    "^/login?direct=1.*$"
              #    "^/login?direct=1/.*$"
              #  ];
              #  subject = "user:admin";
              #  policy = "one_factor";
              #}
              {
                domain = [ # bypass authelia when connecting to authelia itself
                  "identity.${configVars.domain2}"
                ];
                policy = "bypass";
              }
              {
                domain = [ # catchall for any remaining subdomains to only allow chris@dcbond.com to authenticate (assuming 'authelia' traefik middleware set on the service)
                  "*.${configVars.domain2}"
                ];
                subject = "user:admin";
                policy = "one_factor";
              }
            ];
          };
          regulation = {
            max_retries = 3;
            find_time = "5m";
            ban_time = "15m";
          };
          storage = { # return to postgres if declarative passwords added to postgres nixos module, check 25.05 release?
            #postgres = {
            #  address = "unix:///var/run/postgres.sock";
            #  database = "${app}-${configVars.domain2Short}";
            #  username = "${app}-${configVars.domain2Short}";
            #  password = "";
            #};
            local = {
              path = "/var/lib/${app}-${configVars.domain2Short}/sqlite3.db";
            };
          };
          #identity_providers = {
          #  oidc = {
          #    jwks = {
          #      key_id = "${configVars.domain2Short}";
          #      algorithm = "RS256";
          #      use = "sig";
          #    };
          #    clients = [

          #      {
          #      client_name = "Bond Private Nextcloud";
          #      client_id = "7Au52dmVWwvAGdqvrsLatNjedPoSIfQw~UWRj.M24VWhhlDp8v_tXUtePMvCz9pn~Vt1EVBc";
          #      client_secret = "$pbkdf2-sha512$310000$PLcD7uvNnhfoie42zPQ71w$oZhEWIOtCXk/fOG4ABoRqDCTZmsZoxWKH0ERqz19aHkS7igOULjOQpvSHFxth0cuU3nehFYEYaF3Yo.z7vg./A";
          #      public = false;
          #      authorization_policy = "one_factor";
          #      require_pkce = true;
          #      pkce_challenge_method = "S256";
          #      redirect_uris = "https://cloud.${configVars.domain2}/apps/oidc_login/oidc";
          #      scopes = [
          #        "openid"
          #        "profile"
          #        "email"
          #        "groups"
          #      ];
          #      userinfo_signed_response_alg = "none";
          #      token_endpoint_auth_method = "client_secret_basic";
          #      consent_mode = "implicit"; # disable consent screen flow
          #      }
          #      
          #    ];
          #  };
          #};
          notifier = {
            disable_startup_check = false;
            filesystem = {
              filename = "/var/lib/${app}-${configVars.domain2Short}/notifications.txt";
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
          #oidcIssuerPrivateKeyFile = "${config.sops.secrets.autheliaOidcJwksKey.path}";
        };
      };
    }; 

    redis.servers."${app}-${configVars.domain2Short}" = { # service name will be "redis-authelia-opticon"
      enable = true;
      user = "${app}-${configVars.domain2Short}";   
      port = 0;
      unixSocket = "/run/redis-${app}-${configVars.domain2Short}/redis.sock";
      unixSocketPerm = 600;
    };

    #postgresql = {
    #  ensureDatabases = [ "${app}-${configVars.domain2Short}" ];
    #  ensureUsers = [
    #    {
    #      name = "${app}-${configVars.domain2Short}"; 
    #      ensureDBOwnership = true;
    #      ensureClauses.login = true;
    #    }
    #  ];
    #};

    #postgresqlBackup = {
    #  databases = [ "${app}-${configVars.domain2Short}" ];
    #};
      
    # this creates traefik router, middleware, and service called "authelia" that other apps can point to in their traefik configs, need to determine how this interplays with separate instances of authelia?
    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`identity.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [
          "secure-headers"
        ];
        tls = {
          certResolver = "cloudflareDns";
          options = "tls-13@file";
        };
      };
      middlewares = {
        ${app} = {
          forwardAuth = {
            address = "http://127.0.0.1:9091/api/verify?rd=https://identity.${configVars.domain2}";
            trustForwardHeader = true;
            authResponseHeaders = [
              "Remote-User"
              "Remote-Groups"
              "Remote-Name"
              "Remote-Email"
            ];
          };
        };
      };
      services.${app} = {
        loadBalancer = {
          passHostHeader = true;
          servers = [
          {
            url = "http://127.0.0.1:9092";
          }
          ];
        };
      };
    };

  };

}