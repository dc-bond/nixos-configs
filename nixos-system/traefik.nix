{
  config,
  lib,
  pkgs,
  configVars,
  nixServiceRecoveryScript,
  ...
}: 

let

  app = "traefik";
  recoveryPlan = {
    restoreItems = [
      "/var/lib/${app}"
    ];
    stopServices = [ "${app}" ];
    startServices = [ "${app}" ];
  };
  recoverScript = nixServiceRecoveryScript {
    serviceName = app;
    recoveryPlan = recoveryPlan;
  };

in

{

  networking.firewall.allowedTCPPorts = [
    80
    443 
  ];
  
  sops.secrets = {
    cloudflareApiKey = {
      owner = config.users.users.${app}.name;
      group = config.users.users.${app}.group;
      mode = "0440";
    };
  };

  systemd.services.${app} = {
    serviceConfig = {
      LogsDirectory = "${app}"; # creates log directory at /var/log/traefik
    };
    environment = {
      CF_API_EMAIL = configVars.users.chris.email; 
      CF_API_KEY_FILE = "${config.sops.secrets.cloudflareApiKey.path}"; 
    };
  }; 

  users.users.${app}.extraGroups = [ "docker" ]; # add traefik to docker group to enable docker socket access

  backups.serviceHooks = {
    preHook = lib.mkAfter [
      "systemctl stop ${app}.service"
    ];
    postHook = lib.mkAfter [
      "systemctl start ${app}.service"
    ];
  };

  environment.systemPackages = with pkgs; [ recoverScript ];

  services = {

    ${app} = {
      enable = true;

      staticConfigOptions = {
        api = {
          dashboard = true;
          insecure = false;
        };
        log = { # logs to journal under traefik.service
          level = "WARN";
          noColor = false;
        };
        accessLog = {
          filePath = "/var/log/traefik/access.log";
          addInternals = false;
          format = "json";
          bufferingSize = 0;
          filters.statusCodes = [
            "200-206" # 200 ok, 201 created, 204 no content, 206 partial content
            "307-308" # temporary/permanent redirect (more interesting than 301/302)
            "400-499" # client errors (bad requests, unauthorized, forbidden, not found, etc.)
            "500-599" # server errors (internal errors, bad gateway, service unavailable, etc.)
          ];
          fields.headers = {
            defaultMode = "drop"; # default drop all headers
            names = {
              User-Agent = "keep";  # except keep User-Agent header - relevant for CrowdSec to identify bad bots/tools
            };
          };
        };
        metrics.prometheus = {
          entryPoint = "metrics";
          addEntryPointsLabels = true;
          addRoutersLabels = true;
          addServicesLabels = true;
        };
        entryPoints = {
          metrics.address = "127.0.0.1:8082/tcp";
          web = {
            address = "0.0.0.0:80/tcp";
            http.redirections.entrypoint = {
              to = "websecure";
              scheme = "https";
              permanent = true;
            };
          };
          websecure = {
            address = "0.0.0.0:443/tcp";
            forwardedHeaders.trustedIPs = [ # only trust forwarding headers from Cloudflare - https://www.cloudflare.com/ips/
              "103.21.244.0/22"
              "103.22.200.0/22"
              "103.31.4.0/22"
              "104.16.0.0/13"
              "104.24.0.0/14"
              "108.162.192.0/18"
              "131.0.72.0/22"
              "141.101.64.0/18"
              "162.158.0.0/15"
              "172.64.0.0/13"
              "173.245.48.0/20"
              "188.114.96.0/20"
              "190.93.240.0/20"
              "197.234.240.0/22"
              "198.41.128.0/17"
              "2400:cb00::/32"
              "2606:4700::/32"
              "2803:f800::/32"
              "2405:b500::/32"
              "2405:8100::/32"
              "2a06:98c0::/29"
              "2c0f:f248::/32"
            ];
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
              propagation.delayBeforeChecks = 5;
            };
            email = configVars.users.chris.email;
            keyType = "RSA4096";
            certificatesDuration = 180;
            storage = "/var/lib/${app}/acme.json"; # where acme certificates live
            caServer = "https://acme-v02.api.letsencrypt.org/directory";
          };
        };
        providers = {
          docker = {
            endpoint = "unix:///var/run/docker.sock";
            exposedByDefault = false;
            allowEmptyServices = true;
          };
        };
      };

      dynamicConfigOptions = {
        http = {
          routers."${app}-dashboard" = {
            entrypoints = ["websecure"];
            rule = "Host(`${app}-${config.networking.hostName}.${configVars.domain2}`)";
            service = "api@internal";
            middlewares = [
              "trusted-allow"
              "secure-headers"
            ];
            tls = {
              certResolver = "cloudflareDns";
              options = "tls-13@file";
              domains = {
                "0" = {
                  main = "${configVars.domain1}";
                  sans = "*.${configVars.domain1}";
                };
                "1" = {
                  main = "${configVars.domain2}";
                  sans = "*.${configVars.domain2}";
                };
              };
            };
          };
          middlewares = {
            trusted-allow = {
              ipAllowList = {
                sourceRange = [
                  "192.168.1.0/24" # home LAN
                  "${configVars.hosts.juniper.networking.tailscaleIp}" # allow uptime-kuma to access allowList services
                  "${configVars.hosts.thinkpad.networking.tailscaleIp}"
                  "${configVars.hosts.cypress.networking.tailscaleIp}"
                  "${configVars.hosts.alder.networking.tailscaleIp}"
                  "${configVars.devices.chrisIphone15.tailscaleIp}"
                  "${configVars.devices.daniellePixel7a.tailscaleIp}"
                  "${configVars.devices.sydneyIphone6.tailscaleIp}"
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

    logrotate = {
      enable = true;
      settings.traefik = {
        files = "/var/log/traefik/access.log";
        frequency = "daily";
        rotate = 7; # keep 7 days
        compress = true;
        delaycompress = true;  # don't compress most recent rotation
        missingok = true;
        notifempty = true;
        postrotate = "systemctl kill --signal=SIGUSR1 traefik.service";  # tell traefik to reopen log file
      };
    };

    borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter [ "/var/lib/${app}" ];

  };

}