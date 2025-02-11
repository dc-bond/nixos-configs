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

  environment.etc = {
    "matrix-wellknown/matrix-server.json".text = ''
      {
        "m.server": {
          "base_url": "https://matrix.${configVars.domain1}:443"
        }
      }
    '';
    "matrix-wellknown/matrix-client.json".text = ''
      {
        "m.homeserver": {
          "base_url": "https://matrix.${configVars.domain1}"
        }
      }
    '';
  };

  systemd.services.matrix-wellknown-server = {
    description = "python HTTP server for matrix .well-known files";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 -m http.server 8076 --directory /etc/matrix-wellknown";
      #ExecStart = "${pkgs.python3Packages.httpserver}/bin/httpserver -p 8076 --directory /etc/matrix-wellknown";
      WorkingDirectory = "/etc/matrix-wellknown";
      #User = "matrix";
      #Group = "matrix";
      Restart = "always";
      RestartSec = 5;
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
      virtualHosts."${configVars.domain1}" = {
        listen = [
          {
            addr = "127.0.0.1"; 
            port = 8075;
          }
        ];
        enableACME = false;
        forceSSL = false;
        locations."= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
        locations."= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
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
      settings = {
        redis.enabled = true;
        server_name = configVars.domain1;
        public_baseurl = "https://matrix.${configVars.domain1}";
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
        extraConfig = ''
          max_upload_size: "50M"
        '';
      };
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

    traefik.dynamicConfigOptions.http = {
      routers = {
        "${app}" = {
          entrypoints = ["websecure"];
          rule = "Host(`matrix.${configVars.domain1}`)";
          service = "${app}";
          middlewares = [
            "secure-headers"
            #"authelia-dcbond"
          ];
          tls = {
            certResolver = "cloudflareDns";
            options = "tls-13@file";
          };
        };
        "matrix-wellknown-server" = {
          entrypoints = ["websecure"];
          rule = "Host(`${configVars.domain1}`) && PathPrefix(`/.well-known/matrix/server`)";
          service = "matrix-wellknow-server";
          #middlewares = [
          #  "matrix-server-json"
          #];
          tls = {
            certResolver = "cloudflareDns";
            options = "tls-13@file";
          };
        };
        "matrix-wellknown-client" = {
          entrypoints = ["websecure"];
          rule = "Host(`${configVars.domain1}`) && PathPrefix(`/.well-known/matrix/client`)";
          service = "matrix-wellknown-client";
          #middlewares = [
          #  "matrix-client-json"
          #];
          tls = {
            certResolver = "cloudflareDns";
            options = "tls-13@file";
          };
        };
      };
      #middlewares = {
      #  "matrix-server-json".redirectRegex = {
      #    regex = ".*";
      #    replacement = "http://127.0.0.1:8076/matrix-server.json";
      #    permanent = true;
      #  };
      #  "matrix-client-json".redirectRegex = {
      #    regex = ".*";
      #    replacement = "http://127.0.0.1:8076/matrix-client.json";
      #    permanent = true;
      #  };
      #};
      services = {
        "matrix-wellknown-server" = {
          loadBalancer = {
            passHostHeader = true;
            servers = [
              {
                url = "http://127.0.0.1:8076/matrix-server.json";
              }
            ];
          };
        };
        "matrix-wellknown-client" = {
          loadBalancer = {
            passHostHeader = true;
            servers = [
              {
                url = "http://127.0.0.1:8076/matrix-client.json";
              }
            ];
          };
        };
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
      };
    };

  };

}