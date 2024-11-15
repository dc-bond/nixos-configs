{ 
  config, 
  pkgs, 
  configVars,
  ... 
}: 

{

  networking.firewall.allowedTCPPorts = [
    80
    443 
  ];
  
  sops.secrets = {
    cloudflareApiKey = {
      owner = config.users.users.traefik.name;
      group = config.users.users.traefik.group;
      mode = "0440";
    };
    traefikBasicAuth = {
      owner = config.users.users.traefik.name;
      group = config.users.users.traefik.group;
      mode = "0440";
    };
  };

  systemd.services.traefik.environment = {
    CF_API_EMAIL = configVars.userEmail; 
    CF_API_KEY_FILE = "${config.sops.secrets.cloudflareApiKey.path}"; 
  };

  services = {

    traefik = {
      enable = true;
      group = "docker";

      staticConfigOptions = {
        api = {
          dashboard = true;
          insecure = false;
        };
        log = {
          level = "TRACE";
          noColor = false;
          filePath = "/var/lib/traefik/traefik.log";
        };
        accessLog = {
          filePath = "/var/lib/traefik/traefik-access.log";
          addInternals = true;
          bufferingSize = 100;
          filters.statusCodes = [
            "200-206"
            "400-499"
            "500-599"
          ];
        };
        entryPoints = {
          web = {
            address = ":80/tcp";
            http.redirections.entrypoint = {
              to = "websecure";
              scheme = "https";
              permanent = true;
            };
          };
          websecure = {
            address = ":443/tcp";
            #forwardedHeaders.trustedIPs = [
            #  "${configVars.kumaHostVethIp}"
            #  "${configVars.kumaContainerVethIp}"
            #  "169.254.140.143/16"
            #  #"192.168.1.2"
            #  #"192.168.1.62"

            #  "173.245.48.0/20"
            #  "103.21.244.0/22"
            #  "103.22.200.0/22"
            #  "103.31.4.0/22"
            #  "141.101.64.0/18"
            #  "108.162.192.0/18"
            #  "190.93.240.0/20"
            #  "188.114.96.0/20"
            #  "197.234.240.0/22"
            #  "198.41.128.0/17"
            #  "162.158.0.0/15"
            #  "104.16.0.0/12"
            #  "172.64.0.0/13"
            #  "131.0.72.0/22"
            #];
          };
        };
        certificatesResolvers = {
          cloudflareDns.acme = {
            dnsChallenge = {
              provider = "cloudflare";
              resolvers = [
                "1.1.1.1:53" 
                "1.0.0.1:53"
              ];
              delayBeforeCheck = 5;
            };
            email = configVars.userEmail;
            keyType = "RSA4096";
            certificatesDuration = 180;
            storage = "/var/lib/traefik/acme.json"; # where acme certificates live
            caServer = "https://acme-v02.api.letsencrypt.org/directory";
          };
        };
        providers = {
          docker = {
            endpoint = "unix:///var/run/docker.sock";
            exposedByDefault = false;
          };
        };
      };

      dynamicConfigOptions = {
        http = {
          routers.traefik-dashboard = {
            entrypoints = ["websecure"];
            rule = "Host(`traefik.${configVars.domain3}`)";
            service = "api@internal";
            middlewares = [
              #"authelia"
              "secure-headers"
            ];
            tls = {
              certResolver = "cloudflareDns";
              options = "tls-13@file";
              domains = {
                "0" = {
                  main = "${configVars.domain3}";
                  sans = "*.${configVars.domain3}";
                };
              };
            };
          };
          middlewares = {
            #auth = {
            #  basicAuth = {
            #    usersFile = "${config.sops.secrets.traefikBasicAuth.path}";
            #  };
            #};
            authelia = {
              forwardAuth = {
                address = "http://127.0.0.1:9091/api/verify?rd=https://identity.${configVars.domain3}";
                trustForwardHeader = true;
                authResponseHeaders = [
                  "Remote-User"
                  "Remote-Groups"
                  "Remote-Name"
                  "Remote-Email"
                ];
              };
            };
            secure-headers = {
              headers = {
                sslRedirect = true;
                accessControlMaxAge = "100";
                stsSeconds = "31536000"; # force browsers to only connect over https
                stsIncludeSubdomains = true; # force browsers to only connect over https
                stsPreload = true; # force browsers to only connect over https
                forceSTSHeader = true; # force browsers to only connect over https
                contentTypeNosniff = true; # sets x-content-type-options header value to "nosniff", reduces risk of drive-by downloads
                frameDeny = true; # sets x-frame-options header value to "deny", prevents attacker from spoofing website in order to fool users into clicking something that is not there
                browserXssFilter = true; # sets x-xss-protection header value to "1; mode=block", which prevents page from loading if detecting a cross-site scripting attack
                contentSecurityPolicy = [ # sets content-security-policy header to suggested value
                  "default-src"
                  "self"
                ];
                referrerPolicy = "same-origin";
                addVaryHeader = true;
              };
            };
            #auth-chain = {
            #  chain.middlewares = [
            #    "authelia"
            #    "secure-headers" 
            #  ];
            #};
          };
        };
        tls = {
          options = {
            tls-12 = {
              minVersion = "VersionTLS12";
              sniStrict = true;
              cipherSuites = [
                "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
                "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
                "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
                "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
                "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305"
                "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
              ];
            };
            tls-13 = {
              minVersion = "VersionTLS13";
              sniStrict = true;
              curvePreferences = [
                "CurveP521" 
                "CurveP384"
              ];
            };
          };
        };
      };

    };

  };

  systemd.services.traefik.serviceConfig = {
    WorkingDirectory = "/var/lib/traefik/";
  };

}