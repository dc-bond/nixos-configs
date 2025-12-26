{
  config,
  configVars,
  pkgs,
  lib,
  ...
}:

let
  app = "homepage-dashboard";
in

{

  services.${app} = {
    enable = true;
    listenPort = 8083;
    openFirewall = false;

    settings = {
      title = "Bond Homepage";
      favicon = "https://gethomepage.dev/img/favicon.ico";
      headerStyle = "boxed";
      layout = {
        "Services" = {
          style = "row";
          columns = 3;
        };
        "Infrastructure" = {
          style = "row";
          columns = 3;
        };
        "Media" = {
          style = "row";
          columns = 3;
        };
      };
    };

    services = [
      {
        "Aspen Services" = [
          {
            "Traefik" = {
              href = "https://traefik-aspen.${configVars.domain2}/dashboard/#/";
              description = "Reverse Proxy Dashboard";
              ping = "https://traefik-aspen.${configVars.domain2}";
            };
          }
          {
            "Pihole" = {
              href = "https://pihole-aspen.${configVars.domain2}/admin/login";
              description = "DNS Ad Blocker";
              ping = "https://pihole-aspen.${configVars.domain2}";
            };
          }
          {
            "LibreChat" = {
              href = "https://librechat.${configVars.domain2}/";
              description = "AI Chat Interface";
              ping = "https://librechat.${configVars.domain2}";
            };
          }
          {
            "Nextcloud" = {
              href = "https://nextcloud.${configVars.domain1}/";
              description = "Private Cloud";
              ping = "https://nextcloud.${configVars.domain1}";
            };
          }
          {
            "Authelia" = {
              href = "https://identity.${configVars.domain1}/";
              description = "SSO Authentication Portal";
              ping = "https://identity.${configVars.domain1}";
            };
          }
          {
            "Lldap" = {
              href = "https://lldap.${configVars.domain1}/";
              description = "Lightweight LDAP";
              ping = "https://lldap.${configVars.domain1}";
            };
          }
          {
            "Bond Ledger" = {
              href = "https://bond-ledger.${configVars.domain2}/";
              description = "Financial Ledger";
              ping = "https://bond-ledger.${configVars.domain2}";
            };
          }
          {
            "Actual Budget" = {
              href = "https://actual.${configVars.domain2}/";
              description = "Budget Management";
              ping = "https://actual.${configVars.domain2}";
            };
          }
          {
            "Photoprism" = {
              href = "https://photos.${configVars.domain2}/";
              description = "Photo Gallery";
              ping = "https://photos.${configVars.domain2}";
            };
          }
          {
            "Jellyfin" = {
              href = "https://jellyfin.${configVars.domain2}/";
              description = "Media Server";
              ping = "https://jellyfin.${configVars.domain2}";
            };
          }
          {
            "Jellyseerr" = {
              href = "https://jellyseerr.${configVars.domain2}/";
              description = "Media Requests";
              ping = "https://jellyseerr.${configVars.domain2}";
            };
          }
          {
            "Sabnzbd" = {
              href = "https://sabnzbd.${configVars.domain2}/";
              description = "Usenet Downloader";
              ping = "https://sabnzbd.${configVars.domain2}";
            };
          }
          {
            "Prowlarr" = {
              href = "https://prowlarr.${configVars.domain2}/";
              description = "Indexer Manager";
              ping = "https://prowlarr.${configVars.domain2}";
            };
          }
          {
            "Radarr" = {
              href = "https://radarr.${configVars.domain2}/";
              description = "Movie Management";
              ping = "https://radarr.${configVars.domain2}";
            };
          }
          {
            "Sonarr" = {
              href = "https://sonarr.${configVars.domain2}/";
              description = "TV Show Management";
              ping = "https://sonarr.${configVars.domain2}";
            };
          }
          {
            "Frigate" = {
              href = "https://frigate.${configVars.domain2}/";
              description = "NVR Camera System";
              ping = "https://frigate.${configVars.domain2}";
            };
          }
          {
            "Stirling PDF" = {
              href = "https://stirling-pdf.${configVars.domain2}/";
              description = "PDF Tools";
              ping = "https://stirling-pdf.${configVars.domain2}";
            };
          }
          {
            "SearXNG" = {
              href = "https://search.${configVars.domain2}/";
              description = "Private Search Engine";
              ping = "https://search.${configVars.domain2}";
            };
          }
          {
            "RecipeSage" = {
              href = "https://recipesage.${configVars.domain2}/";
              description = "Recipe Manager";
              ping = "https://recipesage.${configVars.domain2}";
            };
          }
          {
            "Grafana" = {
              href = "https://grafana.${configVars.domain2}/";
              description = "Metrics Dashboard";
              ping = "https://grafana.${configVars.domain2}";
            };
          }
          {
            "N8N" = {
              href = "https://n8n.${configVars.domain2}/";
              description = "Workflow Automation";
              ping = "https://n8n.${configVars.domain2}";
            };
          }
          {
            "Unifi" = {
              href = "https://unifi.${configVars.domain2}/";
              description = "Network Controller";
              ping = "https://unifi.${configVars.domain2}";
            };
          }
          {
            "Home Assistant" = {
              href = "https://home-assistant.${configVars.domain2}/";
              description = "Smart Home Hub";
              ping = "https://home-assistant.${configVars.domain2}";
            };
          }
          {
            "Z-Wave" = {
              href = "https://zwavejs.${configVars.domain2}/";
              description = "Z-Wave Controller";
              ping = "https://zwavejs.${configVars.domain2}";
            };
          }
          {
            "Calibre Web" = {
              href = "https://calibre-web.${configVars.domain2}/";
              description = "eBook Library";
              ping = "https://calibre-web.${configVars.domain2}";
            };
          }
          {
            "Chris Workouts" = {
              href = "https://chris-workouts.${configVars.domain2}/";
              description = "Workout Tracker";
              ping = "https://chris-workouts.${configVars.domain2}";
            };
          }
          {
            "Danielle Workouts" = {
              href = "https://danielle-workouts.${configVars.domain2}/";
              description = "Workout Tracker";
              ping = "https://danielle-workouts.${configVars.domain2}";
            };
          }
        ];
      }
      {
        "Juniper Services" = [
          {
            "Traefik" = {
              href = "https://traefik-juniper.${configVars.domain2}/dashboard/#/";
              description = "Reverse Proxy Dashboard";
              ping = "https://traefik-juniper.${configVars.domain2}";
            };
          }
          {
            "Pihole" = {
              href = "https://pihole-juniper.${configVars.domain2}/admin/login";
              description = "DNS Ad Blocker";
              ping = "https://pihole-juniper.${configVars.domain2}";
            };
          }
          {
            "Vaultwarden" = {
              href = "https://vaultwarden.${configVars.domain2}/";
              description = "Password Manager";
              ping = "https://vaultwarden.${configVars.domain2}";
            };
          }
          {
            "Matrix" = {
              href = "https://matrix.${configVars.domain2}/";
              description = "Chat Server";
              ping = "https://matrix.${configVars.domain2}";
            };
          }
        ];
      }
    ];

    bookmarks = [
      {
        "Development & Tech" = [
          {
            "GitHub" = [
              {
                abbr = "GH";
                href = "https://github.com";
              }
            ];
          }
          {
            "Techno Tim" = [
              {
                abbr = "TT";
                href = "https://techno-tim.github.io/";
              }
            ];
          }
          {
            "Git Book" = [
              {
                abbr = "GB";
                href = "https://git-scm.com/book/en/v2";
              }
            ];
          }
        ];
      }
      {
        "NixOS Resources" = [
          {
            "Package Search" = [
              {
                abbr = "PS";
                href = "https://search.nixos.org/packages";
              }
            ];
          }
          {
            "Home Manager Options" = [
              {
                abbr = "HM";
                href = "https://home-manager-options.extranix.com/";
              }
            ];
          }
          {
            "Nix Versions" = [
              {
                abbr = "NV";
                href = "https://lazamar.co.uk/nix-versions/";
              }
            ];
          }
          {
            "NixOS Manual" = [
              {
                abbr = "NM";
                href = "https://nixos.org/manual/nixos/stable/";
              }
            ];
          }
          {
            "NixOS Discourse" = [
              {
                abbr = "ND";
                href = "https://discourse.nixos.org/";
              }
            ];
          }
          {
            "NixOS & Flakes Book" = [
              {
                abbr = "NF";
                href = "https://nixos-and-flakes.thiscute.world/introduction/";
              }
            ];
          }
        ];
      }
      {
        "Tools & Security" = [
          {
            "IP Leak" = [
              {
                abbr = "IP";
                href = "https://ipleak.net/";
              }
            ];
          }
          {
            "Mozilla Observatory" = [
              {
                abbr = "MO";
                href = "https://observatory.mozilla.org/";
              }
            ];
          }
          {
            "MX Toolbox" = [
              {
                abbr = "MX";
                href = "https://mxtoolbox.com/";
              }
            ];
          }
        ];
      }
      {
        "Shopping" = [
          {
            "Amazon" = [
              {
                abbr = "AZ";
                href = "https://www.amazon.com/";
              }
            ];
          }
          {
            "eBay" = [
              {
                abbr = "EB";
                href = "https://www.ebay.com/";
              }
            ];
          }
        ];
      }
      {
        "Financial" = [
          {
            "Capital One" = [
              {
                abbr = "C1";
                href = "https://verified.capitalone.com/sic-ui/#/esignin?Product=360Bank";
              }
            ];
          }
          {
            "PNC Bank" = [
              {
                abbr = "PN";
                href = "https://www.pnc.com/en/personal-banking/banking/online-and-mobile-banking/online-banking.html";
              }
            ];
          }
          {
            "Chase" = [
              {
                abbr = "CH";
                href = "https://secure01b.chase.com/web/auth/";
              }
            ];
          }
          {
            "Vanguard" = [
              {
                abbr = "VG";
                href = "https://investor.vanguard.com/home";
              }
            ];
          }
          {
            "Treasury Direct" = [
              {
                abbr = "TD";
                href = "https://www.treasurydirect.gov/indiv/myaccount/myaccount.htm";
              }
            ];
          }
        ];
      }
    ];

    widgets = [
      {
        logo = {
          icon = "https://gethomepage.dev/img/logo.png";
        };
      }
      {
        search = {
          provider = "duckduckgo";
          target = "_blank";
        };
      }
    ];

    docker = {
      aspen = {
        host = configVars.hosts.aspen.networking.tailscaleIp;
        port = 2375;
      };
    };

    # customCSS = "";
    # customJS = "";
    # environmentFile = null;
    allowedHosts = "homepage.${configVars.domain2}";
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.${app} = {
      entrypoints = ["websecure"];
      rule = "Host(`homepage.${configVars.domain2}`)";
      service = "${app}";
      middlewares = [
        "trusted-allow"
        "secure-headers"
      ];
      tls = {
        certResolver = "cloudflareDns";
        options = "tls-13@file";
      };
    };
    services.${app} = {
      loadBalancer = {
        passHostHeader = true;
        servers = [
          {
            url = "http://127.0.0.1:8083";
          }
        ];
      };
    };
  };

}
