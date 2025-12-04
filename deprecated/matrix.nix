{ 
pkgs,
config,
configVars, 
lib,
... 
}: 

# CREATE NEW USERS WITH 'nix-shell -p matrix-synapse --run "register_new_matrix_user -k "shared-secret" http://127.0.0.1:8008"'

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
      chrisEmailPasswd = {};
      matrixSynapseRegistrationSharedSecret = {};
      matrixSynapseMacaroonSecretKey = {};
      coturnStaticAuthSecret = {
        owner = "${config.users.users.turnserver.name}";
        group = "${config.users.users.turnserver.group}";
        mode = "0440";
      };
    };
    templates = {
      "matrix-extra-conf" = {
        content = ''
          registration_shared_secret: ${config.sops.placeholder.matrixSynapseRegistrationSharedSecret}
          macaroon_secret_key: ${config.sops.placeholder.matrixSynapseMacaroonSecretKey}
          retention: 
            enabled: true
            default_policy:
              min_lifetime: 1d 
              max_lifetime: 1d
            allowed_lifetime_min: 1d
            allowed_lifetime_max: 1d
            purge_jobs:
              - interval: 12h
          email:
            smtp_host: mail.privateemail.com
            smtp_port: 465
            force_tls: true
            smtp_user: ${configVars.users.chris.email}
            smtp_pass: '${config.sops.placeholder.chrisEmailPasswd}'
            notif_from: "Bond Encrypted Communications <noreply@dcbond.com>"
          encryption_enabled_by_default_for_room_type: all
          user_directory:
              enabled: true
              search_all_users: true
              prefer_local_users: true
              show_locked_users: true
          turn_shared_secret: ${config.sops.placeholder.coturnStaticAuthSecret}
        '';
        owner = "${config.users.users.${app}.name}";
        group = "${config.users.users.${app}.group}";
        mode = "0440";
      };
    };
  };

  networking.firewall = {
    allowedUDPPorts = [ 
      3478 
      5349 
    ];
    allowedTCPPorts = [ 
      3478 
      5349 
    ];
    allowedUDPPortRanges = let
      range = with config.services.coturn; [
        {
          from = min-port;
          to = max-port;
        }
      ];
    in range;
  };
  
  systemd.services."${app}" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  services = {

    #postgresql = {
    #  # DOESNT WORK MUST RUN MANUALLY ON FIRST SETUP
    #  #initialScript = pkgs.writeText "${app}-init.sql" ''
    #  #CREATE USER "matrix-synapse";
    #  #CREATE DATABASE "matrix-synapse" ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' template=template0 OWNER "matrix-synapse";
    #  #'';
    #};

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
        #"comms.${configVars.domain1}" = {
        #  enableACME = false;
        #  forceSSL = false;
        #  root = pkgs.element-web.override {
        #    conf = {
        #      #default_theme = "dark";
        #      default_server_config = {
        #        "m.homeserver" = {
        #          "base_url" = "https://matrix.${configVars.domain1}";
        #          "server_name" = "${configVars.domain1}";
        #        };
        #      };
        #      brand = "Bond Encrypted Communications";
        #    };
        #  };
        #  listen = [
        #    {
        #      addr = "127.0.0.1"; 
        #      port = 8077;
        #    }
        #  ];
        #};
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
          level = "WARNING";
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
        enable_registration = false;
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
        turn_uris = [
          #"turn:turn.${configVars.domain1}:3478?transport=tcp" # force UDP
          "turn:turn.${configVars.domain1}:3478?transport=udp" 
          #"turns:turn.${configVars.domain1}:5349?transport=tcp" # force UDP
          "turns:turn.${configVars.domain1}:5349?transport=udp" 
        ];
        turn_user_lifetime = "1h";
        turn_allow_guests = false;
        #workers = {
        #  "client" = {
        #    worker_listeners = [
        #      {
        #        type = "http";
        #        port = 9094;
        #        bind_addresses = [ "127.0.0.1" ];
        #        tls = false;
        #        x_forwarded = true;
        #        resources = [
        #          {
        #          names = [ "client" ];
        #          }
        #        ];
        #      }
        #    ];
        #  };
        #};
      };
      extraConfigFiles = [
        "/run/secrets/rendered/matrix-extra-conf"
      ];
    };

    coturn = rec {
      enable = true;
      no-cli = true;
      no-tcp = true; # force UDP only
      no-udp = false;
      no-tcp-relay = true; # force UDP only
      no-udp-relay = false;
      listening-ips = [ "192.168.1.89" ];
      listening-port = 3478;
      tls-listening-port = 5349;
      relay-ips = ["192.168.1.89" ];
      min-port = 50100;
      max-port = 50200; # only anticipate a handful of concurrent calls, so only opening 100 ports which should still be on the liberal side
      use-auth-secret = true;
      static-auth-secret-file = "${config.sops.secrets.coturnStaticAuthSecret.path}";
      realm = "turn.${configVars.domain1}";
      cert = "/etc/turnserver/cert.pem";
      pkey = "/etc/turnserver/key.pem";
      dh-file = "/etc/turnserver/dh.pem";
      extraConfig = ''
        suppress_key_server_warning=true
        no-multicast-peers
        user-quota=48
        total-quota=4800
        udp-self-balance
        cipher-list=TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256 dh2066
        denied-peer-ip=10.0.0.0-10.255.255.255    
        #denied-peer-ip=192.168.0.0-192.168.255.255
        denied-peer-ip=172.16.0.0-172.31.255.255  
        denied-peer-ip=0.0.0.0-0.255.255.255       
        #denied-peer-ip=100.64.0.0-100.127.255.255  
        denied-peer-ip=127.0.0.0-127.255.255.255   
        denied-peer-ip=169.254.0.0-169.254.255.255 
        denied-peer-ip=192.0.0.0-192.0.0.255       
        denied-peer-ip=192.0.2.0-192.0.2.255       
        denied-peer-ip=192.88.99.0-192.88.99.255   
        denied-peer-ip=198.18.0.0-198.19.255.255   
        denied-peer-ip=198.51.100.0-198.51.100.255 
        denied-peer-ip=203.0.113.0-203.0.113.255   
        denied-peer-ip=240.0.0.0-255.255.255.255   
        denied-peer-ip=::1                         
        denied-peer-ip=fc00::-fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
        denied-peer-ip=fe80::-febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff
      '';
    };
        
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
          #"element-web" = {
          #  entrypoints = ["websecure"];
          #  rule = "Host(`comms.${configVars.domain1}`)";
          #  service = "element-web";
          #  middlewares = [
          #    "secure-headers"
          #  ];
          #  tls = {
          #    certResolver = "cloudflareDns";
          #    options = "tls-13@file";
          #  };
          #};
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
          #"matrix-client-worker" = {
          #  loadBalancer = {
          #    passHostHeader = true;
          #    servers = [
          #      {
          #        url = "http://127.0.0.1:9094";
          #      }
          #    ];
          #  };
          #};
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
          #"element-web" = {
          #  loadBalancer = {
          #    passHostHeader = true;
          #    servers = [
          #      {
          #        url = "http://127.0.0.1:8077";
          #      }
          #    ];
          #  };
          #};
        };
      };
    };

  };

  virtualisation.oci-containers.containers."traefik-certs-dumper" = {
    image = "ghcr.io/kereis/traefik-certs-dumper:latest"; # https://github.com/kereis/traefik-certs-dumper/releases/tag/v1.7.0
    autoStart = true;
    log-driver = "journald";
    volumes = [ 
      "/var/lib/traefik:/traefik:ro" 
      "/etc/turnserver:/output:rw" 
      "traefik-certs-dumper:/var/lib/docker:rw" # not needed for backup
    ];
    environment = { 
      DOMAIN = "${configVars.domain1}";
      OVERRIDE_UID = "249"; # turnserver user
      OVERRIDE_GID = "249"; # turnserver group
    };
    extraOptions = [
      "--network=traefik-certs-dumper"
      "--ip=${configVars.traefikCertsIp}"
      "--tty=true"
      "--stop-signal=SIGINT"
    ];
  };

  environment.systemPackages = with pkgs; [ openssl ];

  systemd = {
    services = { 
      "generate-dhparam" = {
        description = "generate diffie-hellman parameters for coturn";
        after = [ "network.target" ];
        before = [ "docker-traefik-certs-dumper.service" ];
        wantedBy = [ "multi-user.target" ];
        script = ''
          DH_FILE="/etc/turnserver/dh.pem"
          if [ ! -f "$DH_FILE" ]; then
            echo "generating diffie-hellman parameters..."
            mkdir -p /etc/turnserver
            chmod 755 /etc/turnserver
            chown turnserver:turnserver /etc/turnserver
            ${pkgs.openssl}/bin/openssl dhparam -out "$DH_FILE" 2066
            chmod 640 "$DH_FILE"
            chown turnserver:turnserver "$DH_FILE"
          else
            echo "diffie-hellman parameters already exist."
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
      "docker-traefik-certs-dumper" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "generate-dhparam.service"
          "docker-network-traefik-certs-dumper.service"
          "docker-volume-traefik-certs-dumper.service"
        ];
        requires = [
          "generate-dhparam.service"
          "docker-network-traefik-certs-dumper.service"
          "docker-volume-traefik-certs-dumper.service"
        ];
        partOf = [
          "docker-traefik-certs-dumper-root.target"
        ];
        wantedBy = [
          "docker-traefik-certs-dumper-root.target"
        ];
      };
      "docker-volume-traefik-certs-dumper" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect traefik-certs-dumper || docker volume create traefik-certs-dumper
        '';
        partOf = ["docker-traefik-certs-dumper-root.target"];
        wantedBy = ["docker-traefik-certs-dumper-root.target"];
      };
      "docker-network-traefik-certs-dumper" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${pkgs.docker}/bin/docker network rm -f traefik-certs-dumper";
        };
        script = ''
          docker network inspect traefik-certs-dumper || docker network create --subnet ${configVars.traefikCertsSubnet} --driver bridge --scope local --attachable traefik-certs-dumper
        '';
        partOf = ["docker-traefik-certs-dumper-root.target"];
        wantedBy = ["docker-traefik-certs-dumper-root.target"];
      };
    };
    targets."docker-traefik-certs-dumper-root" = {
      unitConfig = {
        Description = "root target for docker-traefik-certs-dumper";
      };
      wantedBy = ["multi-user.target"];
    };
  }; 

}