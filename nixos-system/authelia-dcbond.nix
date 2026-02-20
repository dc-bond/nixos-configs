{ 
  config, 
  lib,
  pkgs, 
  configVars,
  nixServiceRecoveryScript,
  ... 
}:

let

  app = "authelia-${configVars.domain1Short}";
  recoveryPlan = {
    restoreItems = [
      "/var/lib/${app}"
    ];
    stopServices = [ "${app}" "redis-${app}" ];
    startServices = [ "redis-${app}" "${app}" ];
  };
  recoverScript = nixServiceRecoveryScript {
    serviceName = app;
    recoveryPlan = recoveryPlan;
  };

in

{

  sops.secrets = {
    autheliaLdapUserPasswd1 = {
      owner = config.users.users."${app}".name;
      group = config.users.users."${app}".group;
      mode = "0440";
    };
    autheliaJwtSecret1 = {
      owner = config.users.users."${app}".name;
      group = config.users.users."${app}".group;
      mode = "0440";
    };
    autheliaStorageEncryptionKey1 = {
      owner = config.users.users."${app}".name;
      group = config.users.users."${app}".group;
      mode = "0440";
    };
    autheliaSessionSecret1 = {
      owner = config.users.users."${app}".name;
      group = config.users.users."${app}".group;
      mode = "0440";
    };
    autheliaOidcHmacSecret1 = {
      owner = config.users.users."${app}".name;
      group = config.users.users."${app}".group;
      mode = "0440";
    };
    autheliaOidcJwksKey1 = {
      owner = config.users.users."${app}".name;
      group = config.users.users."${app}".group;
      mode = "0440";
    };
  };

  environment.systemPackages = with pkgs; [ recoverScript ];

  systemd.services."${app}" = {
    after = [ "lldap.service" ];
    requires = [ "lldap.service" ];
  };

  backups.serviceHooks = {
    preHook = lib.mkAfter [
      "systemctl stop ${app}.service"
      "systemctl stop redis-${app}.service"
      "sleep 2"
    ];
    postHook = lib.mkAfter [
      "systemctl start redis-${app}.service"
      "systemctl start ${app}.service"
    ];
  };

  services = {

    authelia.instances = {
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
            selection_criteria.user_verification = "preferred";
            timeout = "30s";
          };
          log = {
            level = "info";
            format = "text"; 
            file_path = "/var/lib/${app}/authelia.log";
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
            redis.host = "/run/redis-${app}/redis.sock";
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
              {
                domain = [ "identity.${configVars.domain1}" ]; # bypass authelia when connecting to authelia itself
                policy = "bypass";
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
            #  database = "${app}";
            #  username = "${app}";
            #  password = "";
            #};
            local = {
              path = "/var/lib/${app}/sqlite3.db";
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
                authorization_policy = "one_factor";
                #authorization_policy = "two_factor"; # requires yubikey webauthn
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
              filename = "/var/lib/${app}/notifications.txt";
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

    redis.servers."${app}" = { # service name will be "redis-authelia-dcbond"
      enable = true;
      user = "${app}";   
      port = 0;
      unixSocket = "/run/redis-${app}/redis.sock";
      unixSocketPerm = 600;
    };

    #postgresql = {
    #  ensureDatabases = [ "${app}" ];
    #  ensureUsers = [
    #    {
    #      name = "${app}"; 
    #      ensureDBOwnership = true;
    #      ensureClauses.login = true;
    #    }
    #  ];
    #};

    #postgresqlBackup = {
    #  databases = [ "${app}" ];
    #};
      
    borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;

    # this creates traefik router, middleware, and service called "authelia-dcbond" that other apps can point to in their traefik configs
    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`identity.${configVars.domain1}`)";
        service = "${app}";
        middlewares = [
          "secure-headers"
        ];
        tls = {
          certResolver = "cloudflareDns";
          options = "tls-13@file";
        };
      };
      middlewares.${app} = {
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

  };

}