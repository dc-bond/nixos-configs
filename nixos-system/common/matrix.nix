{ 
pkgs,
config,
configVars, 
lib,
... 
}: 

let
  app = "matrix-synapse";
  fqdn = "matrix.${configVars.domain1}";
  baseUrl = "https://${fqdn}";
  clientConfig."m.homeserver".base_url = baseUrl;
  serverConfig."m.server" = "${fqdn}:443";
  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
in 

{

  sops = {
    secrets = {
      userEmailPasswd = {};
      matrixSynapseRegistrationSharedSecret = {};
      matrixSynapseMacaroonSecretKey = {};
    };
    templates = {
      "matrix-extra-conf" = {
        content = ''
          registration_requires_token: true
          registrations_require_3pid:
            - email
          registration_shared_secret: ${config.sops.placeholder.matrixSynapseRegistrationSharedSecret}
          macaroon_secret_key: ${config.sops.placeholder.matrixSynapseMacaroonSecretKey}
          email:
            smtp_host: mail.privateemail.com
            smtp_port: 465
            force_tls: true
            smtp_user: ${configVars.userEmail}
            smtp_pass: '${config.sops.placeholder.userEmailPasswd}'
            notif_from: "Bond Matrix Server <noreply@dcbond.com>"
        '';
        owner = "${config.users.users.${app}.name}";
        group = "${config.users.users.${app}.group}";
        mode = "0440";
      };
      #"matrix-email-conf" = {
      #  content = ''
      #    email:
      #      smtp_host: mail.privateemail.com
      #      smtp_port: 465
      #      force_tls: true
      #      smtp_user: ${configVars.userEmail}
      #      smtp_pass: '${config.sops.placeholder.userEmailPasswd}'
      #      notif_from: "Bond Matrix Server <noreply@dcbond.com>"
      #  '';
      #  owner = "${config.users.users.${app}.name}";
      #  group = "${config.users.users.${app}.group}";
      #  mode = "0440";
      #};
      #"matrix-registration-secret" = {
      #  content = ''
      #    registration_shared_secret: ${config.sops.placeholder.matrixSynapseRegistrationSharedSecret}
      #  '';
      #  owner = "${config.users.users.${app}.name}";
      #  group = "${config.users.users.${app}.group}";
      #  mode = "0440";
      #};
      #"matrix-macaroon-key" = {
      #  content = ''
      #    macaroon_secret_key: ${config.sops.placeholder.matrixSynapseMacaroonSecretKey}
      #  '';
      #  owner = "${config.users.users.${app}.name}";
      #  group = "${config.users.users.${app}.group}";
      #  mode = "0440";
      #};
    };
  };

  services = {

    postgresql = {
      enable = true;
      # DOESNT WORK MUST RUN MANUALLY ON FIRST SETUP
      #initialScript = pkgs.writeText "${app}-init.sql" ''
      #CREATE USER "matrix-synapse";
      #CREATE DATABASE "matrix-synapse" ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' template=template0 OWNER "matrix-synapse";
      #'';
    };

    postgresqlBackup = {
      databases = ["${app}"];
    };

    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "${configVars.domain1}" = {
          enableACME = false;
          forceSSL = false;
          listen = [
            {
              addr = "127.0.0.1"; 
              port = 8076;
            }
          ];
          locations."= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
          locations."= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
        };
        "comms.${configVars.domain1}" = {
          enableACME = false;
          forceSSL = false;
          root = pkgs.element-web.override {
            conf = {
              default_server_config = {
                "m.homeserver" = {
                  "base_url" = "https://matrix.${configVars.domain1}";
                  "server_name" = "${configVars.domain1}";
                };
              };
              brand = "Bond Encrypted Communications";
            };
          };
          listen = [
            {
              addr = "127.0.0.1"; 
              port = 8077;
            }
          ];
        };
        "matrix.${configVars.domain1}" = {
          enableACME = false;
          forceSSL = false;
          locations."/" = {
            return = "200 '<html><head><title>Not Found</title></head><body><h1>This is not the page you are looking for.</h1></body></html>'";
            extraConfig = "default_type text/html;";
          };
          listen = [
            {
              addr = "127.0.0.1"; 
              port = 8078;
            }
          ];
        };
      };
    };

    ${app} = {
      enable = true;
      configureRedisLocally = true;
      log = {
        disable_existing_loggers = false;
        formatters = {
          journal_fmt = {
            format = "%(name)s: [%(request)s] %(message)s";
          };
        };
        handlers = {
          journal = {
            class = "systemd.journal.JournalHandler";
            formatter = "journal_fmt";
          };
        };
        root = {
          handlers = [
            "journal"
          ];
          level = "INFO";
        };
        version = 1;
      };
      #plugins = with config.services.matrix-synapse.package.plugins; [
      #  matrix-synapse-ldap3
      #];
      settings = {
        redis.enabled = true;
        server_name = configVars.domain1;
        public_baseurl = "https://matrix.${configVars.domain1}";
        enable_registration = true;
        enable_metrics = false;
        database = {
          name = "psycopg2";
          args = {
            user = "${app}";
            database = "${app}";
          };
        };
        listeners = [
          { 
            port = 8008;
            bind_addresses = [ "127.0.0.1" ];
            type = "http";
            tls = false;
            x_forwarded = true;
            resources = [ 
              {
                names = [ 
                  "client" 
                  "federation" 
                ];
                compress = true;
              } 
            ];
          }
        ];
      };
      extraConfigFiles = [
        "/run/secrets/rendered/matrix-extra-conf"
        #(pkgs.writeTextFile {
        #  name = "${app}-extra.conf";
        #  text = ''
        #    modules:
        #      - module: "ldap_auth_provider.LdapAuthProviderModule"
        #        config:
        #          enabled: true
        #          uri: "ldap://127.0.0.1:3890"
        #          start_tls: false
        #          base: "dc=${configVars.domain1Short},dc=com"
        #        attributes:
        #          uid: "cn"
        #          mail: "mail"
        #          name: "givenName"
        #  '';
        #})
      ];
    };

    #coturn = rec {
    #  enable = true;
    #  no-cli = true;
    #  no-tcp-relay = true;
    #  min-port = 49000;
    #  max-port = 50000;
    #  use-auth-secret = true;
    #  static-auth-secret = "will be world readable for local users :(";
    #  realm = "turn.example.com";
    #  cert = "${config.security.acme.certs.${realm}.directory}/full.pem";
    #  pkey = "${config.security.acme.certs.${realm}.directory}/key.pem";
    #  extraConfig = ''
    #    # for debugging
    #    verbose
    #    # ban private IP ranges
    #    no-multicast-peers
    #    denied-peer-ip=0.0.0.0-0.255.255.255
    #    denied-peer-ip=10.0.0.0-10.255.255.255
    #    denied-peer-ip=100.64.0.0-100.127.255.255
    #    denied-peer-ip=127.0.0.0-127.255.255.255
    #    denied-peer-ip=169.254.0.0-169.254.255.255
    #    denied-peer-ip=172.16.0.0-172.31.255.255
    #    denied-peer-ip=192.0.0.0-192.0.0.255
    #    denied-peer-ip=192.0.2.0-192.0.2.255
    #    denied-peer-ip=192.88.99.0-192.88.99.255
    #    denied-peer-ip=192.168.0.0-192.168.255.255
    #    denied-peer-ip=198.18.0.0-198.19.255.255
    #    denied-peer-ip=198.51.100.0-198.51.100.255
    #    denied-peer-ip=203.0.113.0-203.0.113.255
    #    denied-peer-ip=240.0.0.0-255.255.255.255
    #    denied-peer-ip=::1
    #    denied-peer-ip=64:ff9b::-64:ff9b::ffff:ffff
    #    denied-peer-ip=::ffff:0.0.0.0-::ffff:255.255.255.255
    #    denied-peer-ip=100::-100::ffff:ffff:ffff:ffff
    #    denied-peer-ip=2001::-2001:1ff:ffff:ffff:ffff:ffff:ffff:ffff
    #    denied-peer-ip=2002::-2002:ffff:ffff:ffff:ffff:ffff:ffff:ffff
    #    denied-peer-ip=fc00::-fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
    #    denied-peer-ip=fe80::-febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff
    #  '';
    #};

    #networking.firewall = {
    #  interfaces.enp2s0 = let
    #    range = with config.services.coturn; [ {
    #    from = min-port;
    #    to = max-port;
    #  } ];
    #  in
    #  {
    #    allowedUDPPortRanges = range;
    #    allowedUDPPorts = [ 3478 5349 ];
    #    allowedTCPPortRanges = [ ];
    #    allowedTCPPorts = [ 3478 5349 ];
    #  };
    #};

    #security.acme.certs.${config.services.coturn.realm} = {
    #  /* insert here the right configuration to obtain a certificate */
    #  postRun = "systemctl restart coturn.service";
    #  group = "turnserver";
    #};

    ## configure synapse to point users to coturn
    #${app}.settings = with config.services.coturn; {
    #  turn_uris = ["turn:${realm}:3478?transport=udp" "turn:${realm}:3478?transport=tcp"];
    #  turn_shared_secret = static-auth-secret;
    #  turn_user_lifetime = "1h";
    #};

    traefik = {

      staticConfigOptions.entryPoints = {
        matrix-federation = {
          address = ":8448/tcp";
        };
      };

      dynamicConfigOptions.http = {
        routers = {
          "matrix-web" = {
            entrypoints = ["websecure"];
            rule = "Host(`matrix.${configVars.domain1}`)";
            service = "matrix-web";
            middlewares = [
              "secure-headers"
            ];
            tls = {
              certResolver = "cloudflareDns";
              options = "tls-13@file";
            };
          };
          "matrix-client-api" = {
            entrypoints = ["websecure"];
            rule = "Host(`matrix.${configVars.domain1}`) && PathPrefix(`/_matrix`)";
            service = "${app}";
            middlewares = [
              "matrix-headers"
              "matrix-body-limit"
            ];
            tls = {
              certResolver = "cloudflareDns";
              options = "tls-13@file";
            };
          };
          "synapse-client-api" = {
            entrypoints = ["websecure"];
            rule = "Host(`matrix.${configVars.domain1}`) && PathPrefix(`/_synapse/client`)";
            service = "${app}";
            middlewares = [
              "matrix-headers"
              "matrix-body-limit"
            ];
            tls = {
              certResolver = "cloudflareDns";
              options = "tls-13@file";
            };
          };
          "matrix-federation-api" = {
            entrypoints = ["matrix-federation"];
            rule = "Host(`matrix.${configVars.domain1}`) && PathPrefix(`/_matrix`)";
            service = "${app}";
            middlewares = [
              "matrix-headers"
              "matrix-body-limit"
            ];
            tls = {
              certResolver = "cloudflareDns";
              options = "tls-13@file";
            };
          };
          "synapse-federation-api" = {
            entrypoints = ["matrix-federation"];
            rule = "Host(`matrix.${configVars.domain1}`) && PathPrefix(`/_synapse/client`)";
            service = "${app}";
            middlewares = [
              "matrix-headers"
              "matrix-body-limit"
            ];
            tls = {
              certResolver = "cloudflareDns";
              options = "tls-13@file";
            };
          };
          "matrix-wellknown-server" = {
            entrypoints = ["websecure"];
            rule = "Host(`${configVars.domain1}`) && PathPrefix(`/.well-known/matrix/server`)";
            service = "matrix-wellknown";
            tls = {
              certResolver = "cloudflareDns";
              options = "tls-13@file";
            };
          };
          "matrix-wellknown-client" = {
            entrypoints = ["websecure"];
            rule = "Host(`${configVars.domain1}`) && PathPrefix(`/.well-known/matrix/client`)";
            service = "matrix-wellknown";
            tls = {
              certResolver = "cloudflareDns";
              options = "tls-13@file";
            };
          };
          "element-web" = {
            entrypoints = ["websecure"];
            rule = "Host(`comms.${configVars.domain1}`)";
            service = "element-web";
            middlewares = [
              "secure-headers"
            ];
            tls = {
              certResolver = "cloudflareDns";
              options = "tls-13@file";
            };
          };
        };
        middlewares = {
          matrix-body-limit.buffering = {
            maxRequestBodyBytes = 52428800; # 50MB (matches `client_max_body_size 50M`)
          };
          matrix-headers.headers = {
            customRequestHeaders = {
              "X-Forwarded-For" = "client";
              "X-Forwarded-Proto" = "https";
            };
            #sslRedirect = true;
            #stsSeconds = "31536000"; # force browsers to only connect over https
            #stsIncludeSubdomains = true; # force browsers to only connect over https
            #stsPreload = true; # force browsers to only connect over https
            #forceSTSHeader = true; # force browsers to only connect over https
            #contentTypeNosniff = true; # sets x-content-type-options header value to "nosniff", reduces risk of drive-by downloads
            #frameDeny = true; # sets x-frame-options header value to "deny", prevents attacker from spoofing website in order to fool users into clicking something that is not there
            #customFrameOptionsValue = "SAMEORIGIN"; # suggested by nextcloud, overrides frameDeny
            #browserXssFilter = true; # sets x-xss-protection header value to "1; mode=block", which prevents page from loading if detecting a cross-site scripting attack
            #contentSecurityPolicy = [ # sets content-security-policy header to suggested value
            #  "default-src"
            #  "self"
            #];
            #referrerPolicy = "same-origin";
            #addVaryHeader = true; # ensures that the response includes a Vary header (such as Vary: Origin) so that caches treat different origin requests separately
            #accessControlAllowCredentials = true; 
            #accessControlMaxAge = "100";
            #accessControlAllowOrigin = "*";
            #accessControlAllowMethods = "GET, POST, OPTIONS, PUT, DELETE";
            #accessControlAllowHeaders = "Authorization, Content-Type";
            #accessControlExposeHeaders = "Synapse-Trace-Id, Server"
          };
        };
        services = {
          "${app}" = {
            loadBalancer = {
              passHostHeader = true;
              servers = [
                {
                  url = "http://127.0.0.1:8008";
                }
              ];
            };
          };
          "matrix-web" = {
            loadBalancer = {
              passHostHeader = true;
              servers = [
                {
                  url = "http://127.0.0.1:8078";
                }
              ];
            };
          };
          "matrix-wellknown" = {
            loadBalancer = {
              passHostHeader = true;
              servers = [
                {
                  url = "http://127.0.0.1:8076";
                }
              ];
            };
          };
          "element-web" = {
            loadBalancer = {
              passHostHeader = true;
              servers = [
                {
                  url = "http://127.0.0.1:8077";
                }
              ];
            };
          };
        };
      };
    };

  };

}