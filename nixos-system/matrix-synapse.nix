{ 
  pkgs,
  config,
  configVars, 
  lib,
  nixServiceRecoveryScript,
  ... 
}: 

# MATRIX USER MANAGEMENT
#
# CREATE NEW USERS:
#   Get the registration shared secret: sudo cat /run/secrets/rendered/matrix-extra-conf | grep registration_shared_secret
#   Then run: nix-shell -p matrix-synapse --run "register_new_matrix_user -k '<shared-secret>' http://127.0.0.1:8008"
#
# MAKE BOT USERS JOIN ROOMS (after inviting them in Element):
#   1. Get bot's access token by logging in:
#      curl -X POST https://matrix.dcbond.com/_matrix/client/v3/login \
#        -H 'Content-Type: application/json' \
#        -d '{"type": "m.login.password", "user": "bot-username", "password": "bot-password"}'
#
#   2. Make bot join the room (use room ID from Element → Room Settings → Advanced):
#      curl -X POST 'https://matrix.dcbond.com/_matrix/client/r0/join/<room-id>' \
#        -H 'Authorization: Bearer <bot-access-token>' \
#        -H 'Content-Type: application/json' \
#        -d '{}'

let

  app = "matrix-synapse";
  recoveryPlan = {
    restoreItems = [
      "/var/lib/${app}"
      "/var/lib/redis-${app}"
      "/var/backup/postgresql/${app}.sql.gz"
    ];
    db = {
      #type = "postgresql"; # needs preSvcStartHook for custom postgres setup
      user = "${app}";
      name = "${app}";
      dump = "/var/backup/postgresql/${app}.sql.gz";
    };
    stopServices = [ "${app}" "redis-${app}" ];
    startServices = [ "redis-${app}" "${app}" ];
  };
  recoverScript = nixServiceRecoveryScript {
    serviceName = app;
    recoveryPlan = recoveryPlan;
    #dbType = recoveryPlan.db.type;
    preSvcStartHook = ''
      echo "Dropping and recreating PostgreSQL database ${recoveryPlan.db.name} ..."
      su - postgres -c "dropdb --if-exists ${recoveryPlan.db.name}"
      su - postgres -c "createdb -O ${recoveryPlan.db.user} -E UTF8 -l C -T template0 ${recoveryPlan.db.name}"
      echo "Restoring database from ${recoveryPlan.db.dump} ..."
      gunzip -c ${recoveryPlan.db.dump} | su - postgres -c "psql ${recoveryPlan.db.name}"
   '';
  };

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
              max_lifetime: 30d
            allowed_lifetime_min: 1d
            allowed_lifetime_max: 30d
            purge_jobs:
              - interval: 12h
          email:
            smtp_host: ${configVars.mailservers.namecheap.smtpHost}
            smtp_port: ${toString configVars.mailservers.namecheap.smtpPort}
            force_tls: false
            require_transport_security: true
            smtp_user: ${configVars.users.chris.email}
            smtp_pass: ${config.sops.placeholder.chrisEmailPasswd}
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

  environment.systemPackages = with pkgs; [ 
    recoverScript
    openssl 
  ];
  
  backups.serviceHooks = {
    preHook = lib.mkAfter [
      "systemctl stop ${app}.service"
      "systemctl stop redis-${app}.service"
      "sleep 2"
      "systemctl start postgresqlBackup-${app}.service"
    ];
    postHook = lib.mkAfter [
      "systemctl start redis-${app}.service"
      "systemctl start ${app}.service"
    ];
  };
  
  services = {

    #postgresql = {
    #  # DOESNT WORK MUST RUN MANUALLY ON FIRST SETUP OR SEE SYSTEMD SERVICE BELOW
    #  #initialScript = pkgs.writeText "${app}-init.sql" ''
    #  #CREATE USER "matrix-synapse";
    #  #CREATE DATABASE "matrix-synapse" ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' template=template0 OWNER "matrix-synapse";
    #  #'';
    #};

    postgresqlBackup.databases = [ "${app}" ];

    borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;

    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
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
      settings = {
        redis.enabled = true;
        server_name = configVars.domain1;
        public_baseurl = "https://matrix.${configVars.domain1}";
        enable_registration = false;
        enable_metrics = false;
        app_service_config_files = [
          config.sops.templates."matrix-hookshot-registration".path # requires oci-matrix-hookshot.nix module
        ];
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
                ];
                compress = true;
              } 
            ];
          }
        ];
        turn_uris = [
          #"turn:turn.${configVars.domain1}:3478?transport=tcp" # coturn is only listening on UDP, so commented out to not provide TCP option
          "turn:turn.${configVars.domain1}:3478?transport=udp" 
          #"turns:turn.${configVars.domain1}:5349?transport=tcp" # coturn is only listening on UDP, so commented out to not provide TCP option
          "turns:turn.${configVars.domain1}:5349?transport=udp" 
        ];
        turn_user_lifetime = "1h";
        turn_allow_guests = false;
      };
      extraConfigFiles = [ "/run/secrets/rendered/matrix-extra-conf" ];
    };

    coturn = rec {
      enable = true;
      no-cli = true;
      no-tcp = true; # force UDP only
      no-udp = false;
      no-tcp-relay = true; # force UDP only
      no-udp-relay = false;
      listening-ips = [ (configVars.hosts.${config.networking.hostName}.networking.ipv4 or "127.0.0.1") ];
      listening-port = 3478;
      tls-listening-port = 5349;
      relay-ips = [ (configVars.hosts.${config.networking.hostName}.networking.ipv4 or "127.0.0.1") ];
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
        denied-peer-ip=172.16.0.0-172.31.255.255  
        denied-peer-ip=0.0.0.0-0.255.255.255       
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
        #denied-peer-ip=192.168.0.0-192.168.255.255 # commented out to allow VOIP while on LAN
        #denied-peer-ip=100.64.0.0-100.127.255.255 # commented out to allow VOIP while on tailscale
      '';
    };
        
    traefik = {

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
      "--ip=${configVars.containerServices.traefikCerts.containers.certs.ipv4}"
      "--tty=true"
      "--stop-signal=SIGINT"
    ];
  };

  systemd = {
    services = { 

      "${app}-postgres-init" = {
        description = "Initialize postgres database for ${app}";
        after = [ "postgresql.target" ];
        before = [ "${app}.service" ];
        wantedBy = [ "multi-user.target" ];
        path = [ config.services.postgresql.package ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "postgres";
        };
        script = ''
          # check if database exists with wrong settings and recreate if needed
          if psql -lqt | cut -d \| -f 1 | grep -qw "${app}"; then
            # database exists, check if it has correct settings
            ENCODING=$(psql -d "${app}" -t -c "SELECT pg_encoding_to_char(encoding) FROM pg_database WHERE datname = '${app}';")
            COLLATE=$(psql -d "${app}" -t -c "SELECT datcollate FROM pg_database WHERE datname = '${app}';")
            
            if [[ "$ENCODING" != " UTF8" ]] || [[ "$COLLATE" != " C" ]]; then
              echo "database exists but has wrong settings, recreating..."
              dropdb "${app}" || true
              createdb -O "${app}" -E UTF8 -l C -T template0 "${app}"
            fi
          else
            # database doesn't exist, create it
            echo "Creating database ..."
            createuser "${app}" || true
            createdb -O "${app}" -E UTF8 -l C -T template0 "${app}"
          fi
        '';
      };

      "${app}" = {
        requires = [ 
          "postgresql.target" 
          "${app}-postgres-init.service" 
        ];
        after = [ 
          "postgresql.target" 
          "${app}-postgres-init.service" 
        ];
      };

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
          docker network inspect traefik-certs-dumper || docker network create --subnet ${configVars.containerServices.traefikCerts.subnet} --driver bridge --scope local --attachable traefik-certs-dumper
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