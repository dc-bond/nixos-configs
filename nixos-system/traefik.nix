{
  config,
  lib,
  pkgs,
  configVars,
  ...
}:

let
  app = "traefik";

  # common styling for all error pages
  errorPageStyle = ''
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Inter", "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      background: #2E3440;
      color: #ECEFF4;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 20px;
      line-height: 1.6;
    }
    .container {
      background: #3B4252;
      border-radius: 12px;
      padding: 60px 40px;
      text-align: center;
      max-width: 600px;
      box-shadow: 0 8px 24px rgba(0, 0, 0, 0.2);
    }
    .icon {
      font-size: 72px;
      margin-bottom: 24px;
      line-height: 1;
    }
    h1 {
      font-size: 2rem;
      margin-bottom: 16px;
      font-weight: 600;
      color: #ECEFF4;
    }
    p {
      font-size: 1rem;
      color: #D8DEE9;
      margin-bottom: 12px;
    }
    .info-box {
      margin-top: 32px;
      padding: 20px;
      background: #434C5E;
      border-radius: 8px;
      border-left: 4px solid #88C0D0;
    }
    .info-box p {
      margin: 0;
      font-size: 0.95rem;
    }
    .note {
      font-size: 0.875rem;
      color: #D8DEE9;
      margin-top: 24px;
      opacity: 0.8;
    }
    a {
      color: #88C0D0;
      text-decoration: none;
      border-bottom: 1px solid transparent;
      transition: border-color 0.2s;
    }
    a:hover {
      border-bottom-color: #88C0D0;
    }
  '';

  # 502/503/504 - maintenance page
  maintenanceRoot = pkgs.runCommand "maintenance-page" {} ''
    mkdir -p $out
    cat > $out/index.html <<'EOF'
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Service Temporarily Unavailable</title>
      <style>
        ${errorPageStyle}
      </style>
    </head>
    <body>
      <div class="container">
        <div class="icon">🔧</div>
        <h1>Service Temporarily Unavailable</h1>
        <p>This service is currently undergoing scheduled maintenance.</p>
        <p>Normal service will resume shortly.</p>
        <div class="info-box">
          <p><strong>Regular Maintenance Window</strong></p>
          <p>2:30 AM - 3:40 AM EST</p>
        </div>
        <p class="note">
          If you're seeing this outside the maintenance window, the service may be restarting. Please try again in a few moments.
        </p>
      </div>
    </body>
    </html>
    EOF
  '';

  # 403 - forbidden page
  forbiddenRoot = pkgs.runCommand "forbidden-page" {} ''
    mkdir -p $out
    cat > $out/index.html <<'EOF'
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Access Denied</title>
      <style>
        ${errorPageStyle}
        .icon { color: #BF616A; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="icon">🔒</div>
        <h1>Access Denied</h1>
        <p>This service is only accessible from authorized networks.</p>
        <div class="info-box">
          <p><strong>Authorized Access Points:</strong></p>
          <p>• Bond Local Area Network</p>
          <p>• Bond VPN</p>
        </div>
        <p class="note">
          Please connect to the local network or VPN to access this service.
        </p>
      </div>
    </body>
    </html>
    EOF
  '';

  ## 404 - not found page
  #notFoundRoot = pkgs.runCommand "notfound-page" {} ''
  #  mkdir -p $out
  #  cat > $out/index.html <<'EOF'
  #  <!DOCTYPE html>
  #  <html lang="en">
  #  <head>
  #    <meta charset="UTF-8">
  #    <meta name="viewport" content="width=device-width, initial-scale=1.0">
  #    <title>Page Not Found</title>
  #    <style>
  #      ${errorPageStyle}
  #      .icon { color: #81A1C1; }
  #    </style>
  #  </head>
  #  <body>
  #    <div class="container">
  #      <div class="icon">🔍</div>
  #      <h1>Page Not Found</h1>
  #      <p>The page you're looking for doesn't exist or has been moved.</p>
  #      <div class="info-box">
  #        <p><strong>Available Services:</strong></p>
  #        <p><a href="https://homepage.opticon.dev">Homepage Dashboard</a></p>
  #        <p><a href="https://nextcloud.dcbond.com">Nextcloud</a></p>
  #        <p><a href="https://photos.opticon.dev">Photos</a></p>
  #      </div>
  #      <p class="note">
  #        If you believe this is an error, please check the URL and try again.
  #      </p>
  #    </div>
  #  </body>
  #  </html>
  #  EOF
  #'';

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
          serversTransports.default = {
            forwardingTimeouts = {
              dialTimeout = "5s"; # max time to establish connection (down from 30s default)
              responseHeaderTimeout = "10s"; # max time to read response headers - triggers maintenance page faster
            };
          };
          routers."${app}-dashboard" = {
            entrypoints = ["websecure"];
            rule = "Host(`${app}-${config.networking.hostName}.${configVars.domain2}`)";
            service = "api@internal";
            middlewares = [
              "forbidden-page"
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
          #routers.notfound-catchall = {
          #  entrypoints = ["websecure"];
          #  rule = "HostRegexp(`{host:.+}`)";
          #  service = "notfound-page";
          #  priority = 1;
          #  middlewares = [
          #    "secure-headers"
          #  ];
          #  tls = {
          #    certResolver = "cloudflareDns";
          #    options = "tls-13@file";
          #  };
          #};
          middlewares = {
            trusted-allow = {
              ipAllowList = {
                sourceRange = [
                  "192.168.1.0/24" # home LAN
                  "${configVars.hosts.aspen.networking.tailscaleIp}" # server - for blackbox monitoring
                  "${configVars.hosts.juniper.networking.tailscaleIp}" # server - for blackbox monitoring
                  "${configVars.hosts.thinkpad.networking.tailscaleIp}"
                  "${configVars.hosts.cypress.networking.tailscaleIp}"
                  "${configVars.hosts.alder.networking.tailscaleIp}"
                  "${configVars.hosts.kauri.networking.tailscaleIp}"
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
            maintenance-page = {
              errors = {
                status = ["502" "503" "504"];
                service = "maintenance-page";
                query = "/";
              };
            };
            forbidden-page = {
              errors = {
                status = ["403"];
                service = "forbidden-page";
                query = "/";
              };
            };
          };
          services = {
            maintenance-page = {
              loadBalancer = {
                servers = [
                  {
                    url = "http://127.0.0.1:9018";
                  }
                ];
              };
            };
            forbidden-page = {
              loadBalancer = {
                servers = [
                  {
                    url = "http://127.0.0.1:9019";
                  }
                ];
              };
            };
            #notfound-page = {
            #  loadBalancer = {
            #    servers = [
            #      {
            #        url = "http://127.0.0.1:9020";
            #      }
            #    ];
            #  };
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
                "X25519"      # modern, fast, preferred by most devices
                "CurveP256"   # widely supported, required by some devices
                "CurveP384"   # high security
                "CurveP521"   # highest security
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

    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."maintenance-page" = {
        enableACME = false;
        forceSSL = false;
        root = "${maintenanceRoot}";
        listen = [
          {
            addr = "127.0.0.1";
            port = 9018;
          }
        ];
      };
      virtualHosts."forbidden-page" = {
        enableACME = false;
        forceSSL = false;
        root = "${forbiddenRoot}";
        listen = [
          {
            addr = "127.0.0.1";
            port = 9019;
          }
        ];
      };
      #virtualHosts."notfound-page" = {
      #  enableACME = false;
      #  forceSSL = false;
      #  root = "${notFoundRoot}";
      #  listen = [
      #    {
      #      addr = "127.0.0.1";
      #      port = 9020;
      #    }
      #  ];
      #};
    };

  };

}