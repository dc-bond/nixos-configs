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
  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";
  recoveryPlan = {
    serviceName = "${app}";
    localRestoreRepoPath = "${config.backups.borgDir}/${config.networking.hostName}";
    cloudRestoreRepoPath = "${config.backups.borgCloudDir}/${config.networking.hostName}";
    restoreItems = [
      "/var/lib/${app}"
      "/var/lib/redis-${app}"
      "/var/backup/postgresql/${app}.sql.gz"
    ];
    db = {
      user = "${app}";
      name = "${app}";
      dump = "/var/backup/postgresql/${app}.sql.gz";
    };
    stopServices = [ "${app}" "redis-${app}" ];
    startServices = [ "redis-${app}" "${app}" ];
  };
  recoverMatrixScript = pkgs.writeShellScriptBin "recoverMatrix" ''
    #!/bin/bash
   
    # track errors
    set -euo pipefail

    # set borg passphrase environment variable
    export BORG_PASSPHRASE=$(cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

    # repo selection
    read -p "Use cloud repo? (y/N): " use_cloud
    if [[ "$use_cloud" =~ ^[Yy]$ ]]; then
      REPO="${recoveryPlan.cloudRestoreRepoPath}"
      echo "Using cloud repo"
    else
      REPO="${recoveryPlan.localRestoreRepoPath}"
      echo "Using local repo"
    fi

    # archive selection
    echo "Available archives at $REPO:"
    echo ""
    archives=$(${pkgs.borgbackup}/bin/borg list --short "$REPO")
    echo "$archives" | nl -w2 -s') '
    echo ""
    read -p "Enter number: " num
    ARCHIVE=$(echo "$archives" | sed -n "''${num}p")
    if [ -z "$ARCHIVE" ]; then
      echo "Invalid selection"
      exit 1
    fi
    echo "Selected: $ARCHIVE"

    # stop services
    for svc in ${lib.concatStringsSep " " recoveryPlan.stopServices}; do
      echo "Stopping $svc ..."
      systemctl stop "$svc" || true
    done

    # extract data from archive and overwrite existing data
    cd /
    echo "Extracting data from $REPO::$ARCHIVE ..."
    ${pkgs.borgbackup}/bin/borg extract --verbose --list "$REPO"::"$ARCHIVE" ${lib.concatStringsSep " " recoveryPlan.restoreItems}
    
    # drop and recreate database
    echo "Dropping and recreating clean database ${recoveryPlan.db.name} ..."
    su - postgres -c "dropdb --if-exists ${recoveryPlan.db.name}"
    su - postgres -c "createdb -O ${recoveryPlan.db.user} -E UTF8 -l C -T template0 ${recoveryPlan.db.name}"
    
    # restore database from dump backup
    echo "Restoring database from ${recoveryPlan.db.dump} ..."
    gunzip -c ${recoveryPlan.db.dump} | su - postgres -c "psql ${recoveryPlan.db.name}"

    # start services
    for svc in ${lib.concatStringsSep " " recoveryPlan.startServices}; do
      echo "Starting $svc ..."
      systemctl start "$svc" || true
    done

    echo "Recovery complete!"
  '';
in 

{

  sops = {
    secrets = {
      chrisEmailPasswd = {};
      borgCryptPasswd = {};
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
            smtp_port: 587
            force_tls: false
            require_transport_security: true
            smtp_user: ${configVars.userEmail}
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
    recoverMatrixScript
    openssl 
  ];
  
  backups.serviceHooks = {
    preStop = lib.mkAfter [
      "systemctl stop ${app}.service"
      "systemctl stop redis-${app}.service"
      "sleep 2"
      "systemctl start postgresqlBackup-${app}.service"
    ];
    postStart = lib.mkAfter [
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

    borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter [
      "/var/lib/${app}"
      "/var/lib/redis-${app}"
      "/var/backup/postgresql/${app}.sql.gz"
    ];

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
      listening-ips = [ "${configVars.juniperIp}" ];
      listening-port = 3478;
      tls-listening-port = 5349;
      relay-ips = ["${configVars.juniperIp}" ];
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
      "--ip=${configVars.traefikCertsIp}"
      "--tty=true"
      "--stop-signal=SIGINT"
    ];
  };

  systemd = {
    services = { 

      "${app}-postgres-init" = {
        description = "Initialize postgres database for ${app}";
        after = [ "postgresql.service" ];
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
          "postgresql.service" 
          "${app}-postgres-init.service" 
        ];
        after = [ 
          "postgresql.service" 
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