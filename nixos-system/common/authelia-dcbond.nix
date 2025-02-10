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
    autheliaLdapUserPasswd1 = {
      owner = config.users.users."${app}-${configVars.domain1Short}".name;
      group = config.users.users."${app}-${configVars.domain1Short}".group;
      mode = "0440";
    };
    autheliaJwtSecret1 = {
      owner = config.users.users."${app}-${configVars.domain1Short}".name;
      group = config.users.users."${app}-${configVars.domain1Short}".group;
      mode = "0440";
    };
    autheliaStorageEncryptionKey1 = {
      owner = config.users.users."${app}-${configVars.domain1Short}".name;
      group = config.users.users."${app}-${configVars.domain1Short}".group;
      mode = "0440";
    };
    autheliaSessionSecret1 = {
      owner = config.users.users."${app}-${configVars.domain1Short}".name;
      group = config.users.users."${app}-${configVars.domain1Short}".group;
      mode = "0440";
    };
    autheliaOidcHmacSecret1 = {
      owner = config.users.users."${app}-${configVars.domain1Short}".name;
      group = config.users.users."${app}-${configVars.domain1Short}".group;
      mode = "0440";
    };
    autheliaOidcJwksKey1 = {
      owner = config.users.users."${app}-${configVars.domain1Short}".name;
      group = config.users.users."${app}-${configVars.domain1Short}".group;
      mode = "0440";
    };
  };

  services = {

    ${app}.instances = {
      "${configVars.domain1Short}" = {
        enable = true; 
        settings = {
          theme = "dark";
          totp = {
            disable = true;
          };
          default_2fa_method = "webauthn";
          webauthn = {
            disable = false;
            display_name = "Two-Factor Authentication (2FA)";
            attestation_conveyance_preference = "indirect";
            user_verification = "preferred";
            timeout = "30s";
          };
          log = {
            level = "info";
            format = "text"; 
            file_path = "/var/lib/${app}-${configVars.domain1Short}/authelia.log";
            keep_stdout = true;
          };
          server.address = "tcp://:9091";
          session = {
            cookies = [
              {
              domain = "${configVars.domain1}";
              authelia_url = "https://identity.${configVars.domain1}";
              }
            ];
            redis.host = "/run/redis-${app}-${configVars.domain1Short}/redis.sock";
          };
          authentication_backend = {
            refresh_interval = "5m";
            password_reset.disable = true;
            ldap = {
              address = "ldap://127.0.0.1:3890";
              base_dn = "dc=${configVars.domain1Short},dc=com";
              user = "uid=admin,ou=people,dc=${configVars.domain1Short},dc=com"; # admin username, password in env variable below
              users_filter = "(&(|({username_attribute}={input})({mail_attribute}={input}))(objectClass=person))"; # allow sign in with username OR email
              groups_filter = "(member={dn})";
            };
          };
          access_control = {
            default_policy = "deny";
            rules = [
              #{
              #  domain = ["cloud.${configVars.domain1}"];# only allow chris@dcbond.com user to authenticate to nextcloud admin/login 
              #  resources = [
              #    "^/login?direct=1.*$"
              #    "^/login?direct=1/.*$"
              #  ];
              #  subject = "user:admin";
              #  policy = "one_factor";
              #}
              {
                domain = [ # root domain
                  "${configVars.domain1}"
                ];
                subject = "user:admin";
                policy = "two_factor";
              }
              {
                domain = [ # bypass authelia when connecting to authelia itself
                  "identity.${configVars.domain1}"
                ];
                policy = "bypass";
              }
              {
                domain = [ # bypass authelia when connecting to authelia itself
                  "lldap.${configVars.domain1}"
                ];
                subject = [ # only allow admin and danielle-bond users to access lldap and only require one factor
                  "user:admin"
                  "user:danielle-bond"
                ];
                policy = "one_factor";
              }
              {
                domain = [ # catchall for any remaining subdomains to only allow admin user to authenticate (assuming 'authelia-dcbond' traefik middleware set on the service)
                  "*.${configVars.domain1}"
                ];
                subject = "user:admin";
                policy = "two_factor";
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
            #  database = "${app}-${configVars.domain1Short}";
            #  username = "${app}-${configVars.domain1Short}";
            #  password = "";
            #};
            local = {
              path = "/var/lib/${app}-${configVars.domain1Short}/sqlite3.db";
            };
          };
          identity_providers = {
            oidc = {
              jwks = {
                key_id = "${configVars.domain1Short}";
                algorithm = "RS256";
                use = "sig";
              };
              clients = [

                {
                client_name = "Tailscale SSO";
                client_id = "bond-tailnet";
                client_secret = "$pbkdf2-sha512$310000$wFwB54/jYlnRZPYwL5Yj2A$6Umdwy/f6h5.GPITzV0PLg3r1vSUn5NsmaxJc6qZo7hkZbs4pixefwSA2DaZb0AQO4VawZPt7x7Zhyc4qMeINA";
                redirect_uris = "https://login.tailscale.com/a/oauth_response";
                scopes = [
                  "openid"
                  "profile"
                  "email"
                ];
                consent_mode = "implicit"; # disable consent screen flow
                }

                #{
                #client_name = "Bond Private Nextcloud";
                #client_id = "7Au52dmVWwvAGdqvrsLatNjedPoSIfQw~UWRj.M24VWhhlDp8v_tXUtePMvCz9pn~Vt1EVBc";
                #client_secret = "$pbkdf2-sha512$310000$PLcD7uvNnhfoie42zPQ71w$oZhEWIOtCXk/fOG4ABoRqDCTZmsZoxWKH0ERqz19aHkS7igOULjOQpvSHFxth0cuU3nehFYEYaF3Yo.z7vg./A";
                #public = false;
                #authorization_policy = "one_factor";
                #require_pkce = true;
                #pkce_challenge_method = "S256";
                #redirect_uris = "https://cloud.${configVars.domain1}/apps/oidc_login/oidc";
                #scopes = [
                #  "openid"
                #  "profile"
                #  "email"
                #  "groups"
                #];
                #userinfo_signed_response_alg = "none";
                #token_endpoint_auth_method = "client_secret_basic";
                #consent_mode = "implicit"; # disable consent screen flow
                #}
                
              ];
            };
          };
          notifier = {
            disable_startup_check = false;
            filesystem = {
              filename = "/var/lib/${app}-${configVars.domain1Short}/notifications.txt";
            };
          };
        };
        environmentVariables = {
          AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = "${config.sops.secrets.autheliaLdapUserPasswd1.path}";
        };
        secrets = {
          jwtSecretFile = "${config.sops.secrets.autheliaJwtSecret1.path}";
          storageEncryptionKeyFile = "${config.sops.secrets.autheliaStorageEncryptionKey1.path}";
          sessionSecretFile = "${config.sops.secrets.autheliaSessionSecret1.path}";
          oidcHmacSecretFile = "${config.sops.secrets.autheliaOidcHmacSecret1.path}";
          oidcIssuerPrivateKeyFile = "${config.sops.secrets.autheliaOidcJwksKey1.path}";
        };
      };
    }; 

    redis.servers."${app}-${configVars.domain1Short}" = { # service name will be "redis-authelia-dcbond"
      enable = true;
      user = "${app}-${configVars.domain1Short}";   
      port = 0;
      unixSocket = "/run/redis-${app}-${configVars.domain1Short}/redis.sock";
      unixSocketPerm = 600;
    };

    #postgresql = {
    #  ensureDatabases = [ "${app}-${configVars.domain1Short}" ];
    #  ensureUsers = [
    #    {
    #      name = "${app}-${configVars.domain1Short}"; 
    #      ensureDBOwnership = true;
    #      ensureClauses.login = true;
    #    }
    #  ];
    #};

    #postgresqlBackup = {
    #  databases = [ "${app}-${configVars.domain1Short}" ];
    #};
      
    # this creates traefik router, middleware, and service called "authelia-dcbond" that other apps can point to in their traefik configs
    traefik.dynamicConfigOptions.http = {
      routers.authelia-dcbond = {
        entrypoints = ["websecure"];
        rule = "Host(`identity.${configVars.domain1}`)";
        service = "authelia-dcbond";
        middlewares = [
          "secure-headers"
        ];
        tls = {
          certResolver = "cloudflareDns";
          options = "tls-13@file";
        };
      };
      middlewares.authelia-dcbond = {
        forwardAuth = {
          address = "http://127.0.0.1:9091/api/verify?rd=https://identity.${configVars.domain1}";
          trustForwardHeader = true;
          authResponseHeaders = [
            "Remote-User"
            "Remote-Groups"
            "Remote-Name"
            "Remote-Email"
          ];
        };
      };
      services.authelia-dcbond = {
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

  };

}