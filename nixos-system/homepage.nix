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
      statusStyle = "basic";
      theme = "dark";
      color = "slate";
      hideVersion = true;
      disableCollapse = false;
      hideThemeToggle = true;
      hideReload = true;
      layout = {
        "Services" = {
          style = "row";
          columns = 5;
        };
      };
    };

    services = [
      {
        "Services" = [
          {
            "Traefik-Aspen" = {
              href = "https://traefik-aspen.${configVars.domain2}/dashboard/#/";
              description = "Reverse Proxy Dashboard";
              ping = "https://traefik-aspen.${configVars.domain2}";
            };
          }
          {
            "Traefik-Juniper" = {
              href = "https://traefik-juniper.${configVars.domain2}/dashboard/#/";
              description = "Reverse Proxy Dashboard";
              ping = "https://traefik-juniper.${configVars.domain2}";
            };
          }
          {
            "Pihole-Aspen" = {
              href = "https://pihole-aspen.${configVars.domain2}/admin/login";
              description = "DNS Ad Blocker";
              ping = "https://pihole-aspen.${configVars.domain2}";
            };
          }
          {
            "Pihole-Juniper" = {
              href = "https://pihole-juniper.${configVars.domain2}/admin/login";
              description = "DNS Ad Blocker";
              ping = "https://pihole-juniper.${configVars.domain2}";
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
            "Grafana" = {
              href = "https://grafana.${configVars.domain2}/";
              description = "Metrics Dashboard";
              ping = "https://grafana.${configVars.domain2}";
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
            "Vaultwarden" = {
              href = "https://vaultwarden.${configVars.domain2}/";
              description = "Password Manager";
              ping = "https://vaultwarden.${configVars.domain2}";
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
            "Photoprism" = {
              href = "https://photos.${configVars.domain2}/";
              description = "Photo Gallery";
              ping = "https://photos.${configVars.domain2}";
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
            "Sabnzbd" = {
              href = "https://sabnzbd.${configVars.domain2}/";
              description = "Downloader";
              ping = "https://sabnzbd.${configVars.domain2}";
            };
          }
          {
            "Prowlarr" = {
              href = "https://prowlarr.${configVars.domain2}/";
              description = "Indexer Management";
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
            "Nextcloud" = {
              href = "https://nextcloud.${configVars.domain1}/";
              description = "Private Cloud";
              ping = "https://nextcloud.${configVars.domain1}";
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
            "N8N" = {
              href = "https://n8n.${configVars.domain2}/";
              description = "Workflow Automation";
              ping = "https://n8n.${configVars.domain2}";
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
            "Frigate" = {
              href = "https://frigate.${configVars.domain2}/";
              description = "NVR Camera System";
              ping = "https://frigate.${configVars.domain2}";
            };
          }
          {
            "Matrix" = {
              href = "https://matrix.${configVars.domain1}/";
              description = "Chat Server";
              ping = "https://matrix.${configVars.domain1}";
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
    ];

    widgets = [
      {
        greeting = {
          text_size = "xl";
          text = "Welcome to Bond Network";
        };
      }
      {
        datetime = {
          text_size = "sm";
          format = {
            dateStyle = "full";
            timeStyle = "short";
            hour12 = true;
          };
        };
      }
    ];

    #docker = {
    #  aspen = {
    #    host = configVars.hosts.aspen.networking.tailscaleIp;
    #    port = 2375;
    #  };
    #};

    customCSS = ''
      :root {
        --nord-polar-night-1: #2e3440;
        --nord-polar-night-2: #3b4252;
        --nord-polar-night-3: #434c5e;
        --nord-polar-night-4: #4c566a;
        --nord-snow-storm-1: #d8dee9;
        --nord-snow-storm-2: #e5e9f0;
        --nord-snow-storm-3: #eceff4;
        --nord-frost-1: #8fbcbb;
        --nord-frost-2: #88c0d0;
        --nord-frost-3: #81a1c1;
        --nord-frost-4: #5e81ac;
        --nord-aurora-red: #bf616a;
        --nord-aurora-orange: #d08770;
        --nord-aurora-yellow: #ebcb8b;
        --nord-aurora-green: #a3be8c;
        --nord-aurora-purple: #b48ead;
      }

      ::-webkit-scrollbar {
        width: 8px;
        height: 8px;
      }

      ::-webkit-scrollbar-track {
        background: var(--nord-polar-night-1);
        border-radius: 4px;
      }

      ::-webkit-scrollbar-thumb {
        background: var(--nord-polar-night-4);
        border-radius: 4px;
        transition: background 0.3s ease;
      }

      ::-webkit-scrollbar-thumb:hover {
        background: var(--nord-frost-3);
      }

      /* Hide Services header */
      .services-group h2 {
        display: none !important;
      }

      /* Widgets */
      .widget {
        background: rgba(67, 76, 94, 0.5) !important;
      }

      /* Service Links */
      .service a {
        color: var(--nord-snow-storm-1) !important;
        text-decoration: none !important;
      }

      .service-title {
        font-weight: 500 !important;
        color: var(--nord-snow-storm-2) !important;
        transition: color 0.2s ease !important;
      }

      .service:hover .service-title {
        color: var(--nord-frost-2) !important;
      }

      .service-description {
        color: var(--nord-snow-storm-1) !important;
        opacity: 0.6 !important;
      }

      /* Status Indicators with pulse */
      .service-ping {
        transition: all 0.3s ease !important;
      }

      .service-ping.online {
        background: var(--nord-aurora-green) !important;
        animation: pulse-green 2s ease-in-out infinite !important;
      }

      .service-ping.offline {
        background: var(--nord-aurora-red) !important;
      }

      @keyframes pulse-green {
        0%, 100% {
          opacity: 1;
          transform: scale(1);
        }
        50% {
          opacity: 0.7;
          transform: scale(1.1);
        }
      }


      /* Overall page subtle background */
      body {
        background: var(--nord-polar-night-1) !important;
      }

      /* Smooth transitions */
      * {
        transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1) !important;
      }

      /* Hide reload button */
      button[aria-label="Refresh"],
      button[title="Refresh"],
      .refresh-button,
      button[class*="refresh"],
      button[class*="reload"],
      [aria-label*="eload"],
      [title*="eload"],
      .fixed.bottom-0.right-0,
      .fixed.bottom-2.right-2,
      .fixed.bottom-4.right-4 {
        display: none !important;
      }

      /* Matrix Rain Canvas */
      #matrix-rain {
        position: fixed !important;
        top: 0 !important;
        left: 0 !important;
        width: 100% !important;
        height: 100% !important;
        z-index: -1 !important;
        pointer-events: none !important;
      }
    '';

    customJS = ''
      // Minimal Matrix Rain Effect
      (function() {
        const canvas = document.createElement('canvas');
        canvas.id = 'matrix-rain';
        document.body.appendChild(canvas);

        const ctx = canvas.getContext('2d');

        function resizeCanvas() {
          canvas.width = window.innerWidth;
          canvas.height = window.innerHeight;
        }
        resizeCanvas();
        window.addEventListener('resize', resizeCanvas);

        const fontSize = 14;
        const columns = Math.floor(canvas.width / fontSize);
        const drops = Array(columns).fill(1);

        // Characters to use (mix of alphanumeric and some symbols)
        const chars = '01アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン';

        function draw() {
          // Semi-transparent black to create fade effect
          ctx.fillStyle = 'rgba(46, 52, 64, 0.05)'; // Very subtle fade using Nord Polar Night
          ctx.fillRect(0, 0, canvas.width, canvas.height);

          // Set text style - using Nord Frost-2 color
          ctx.fillStyle = 'rgba(136, 192, 208, 0.15)'; // Very low opacity for subtlety
          ctx.font = fontSize + 'px monospace';

          for (let i = 0; i < drops.length; i++) {
            // Random character
            const text = chars[Math.floor(Math.random() * chars.length)];
            const x = i * fontSize;
            const y = drops[i] * fontSize;

            ctx.fillText(text, x, y);

            // Reset drop randomly or when it reaches bottom
            if (y > canvas.height && Math.random() > 0.975) {
              drops[i] = 0;
            }

            drops[i]++;
          }
        }

        // Slower animation for minimal effect (every 50ms instead of every frame)
        setInterval(draw, 50);
      })();
    '';

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
