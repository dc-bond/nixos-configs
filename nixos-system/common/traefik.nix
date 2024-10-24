{ 
  self, 
  config, 
  lib, 
  pkgs, 
  ... 
}: 

{
  
  sops.secrets.cloudflareApiKey = {
    owner = config.users.users.traefik.name;
    group = config.users.users.traefik.group;
    mode = "0440";
  };

  systemd.services.traefik.environment = {
    CF_API_EMAIL = "chris@dcbond.com"; 
    CF_API_KEY_FILE = "${config.sops.secrets.cloudflareApiKey.path}"; 
  };

  services = {

    traefik = {
      enable = true;

      staticConfigOptions = {
        api = {
          dashboard = true;
        };
        entryPoints = {
          web = {
            address = ":80/tcp";
            http = {
              redirections = {
                entrypoint = {
                  to = "websecure";
                  scheme = "https";
                  permanent = true;
                };
              };
            };
          };
          websecure = {
            address = ":443/tcp";
            forwardedHeaders.trustedIPs = "173.245.48.0/20,103.21.244.0/22,103.22.200.0/22,103.31.4.0/22,141.101.64.0/18,108.162.192.0/18,190.93.240.0/20,188.114.96.0/20,197.234.240.0/22,198.41.128.0/17,162.158.0.0/15,104.16.0.0/12,172.64.0.0/13,131.0.72.0/22";
          };
          certificatesresolvers = {
            cloudflare-dns = {
              acme = {
                dnschallenge = {
                  provider = "cloudflare";
                  resovlers = "1.1.1.1:53,1.0.0.1:53";
                  delaybeforecheck = 5;
                };
                email = "chris@dcbond.com";
                keyType = "RSA4096";
                certificatesDuration = 2160;
                storage = "/var/lib/traefik/acme.json"; # where acme certificates live
                caServer = "https://acme-v02.api.letsencrypt.org/directory";
              };
            };
          };
        };
      };

      dynamicConfigOptions = {
        tls = {
          options = {
            tls-12 = {
              minVersion = "VersionTLS12";
              sniStrict = true;
              #cipherSuites = [
              #  TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
              #  TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
              #  TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
              #  TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
              #  TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305
              #  TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
              #];
            };
            tls-13 = {
              minVersion = "VersionTLS13";
              sniStrict = true;
              curvePreferences = ["CurveP521" "CurveP384"];
            };
          };
        };
      };

    };

  };

}