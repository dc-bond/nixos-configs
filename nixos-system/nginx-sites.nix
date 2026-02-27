{
pkgs,
config,
configVars,
lib,
...
}:

let

  # maintenance page directory with index.html
  maintenanceRoot = pkgs.runCommand "maintenance-page" {} ''
    mkdir -p $out
    cat > $out/index.html <<'EOF'
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Scheduled Maintenance</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: #fff;
          display: flex;
          align-items: center;
          justify-content: center;
          min-height: 100vh;
          padding: 20px;
        }
        .container {
          background: rgba(255, 255, 255, 0.1);
          backdrop-filter: blur(10px);
          border-radius: 20px;
          padding: 60px 40px;
          text-align: center;
          max-width: 600px;
          box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
          border: 1px solid rgba(255, 255, 255, 0.18);
        }
        .icon {
          font-size: 80px;
          margin-bottom: 20px;
          animation: pulse 2s ease-in-out infinite;
        }
        @keyframes pulse {
          0%, 100% { transform: scale(1); }
          50% { transform: scale(1.1); }
        }
        h1 {
          font-size: 2.5em;
          margin-bottom: 20px;
          font-weight: 700;
        }
        p {
          font-size: 1.2em;
          line-height: 1.6;
          margin-bottom: 15px;
          opacity: 0.95;
        }
        .time {
          font-size: 1em;
          margin-top: 30px;
          padding: 15px;
          background: rgba(255, 255, 255, 0.1);
          border-radius: 10px;
          font-weight: 500;
        }
        .note {
          font-size: 0.9em;
          margin-top: 20px;
          opacity: 0.8;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="icon">🔧</div>
        <h1>Scheduled Maintenance</h1>
        <p>This service is temporarily unavailable due to nightly backups.</p>
        <p>All services will be restored shortly.</p>
        <div class="time">
          ⏰ Backup Window: 2:30 AM - 3:40 AM EST
        </div>
        <p class="note">
          If you're seeing this outside the maintenance window, please try again in a few moments.
        </p>
      </div>
    </body>
    </html>
    EOF
  '';

in

{

  systemd.tmpfiles.rules = [
    "L+ /var/www/weekly-recipes.opticon.dev - - - - /var/lib/nextcloud/data/Chris\\040Bond/files/Personal/misc/weekly-recipes.opticon.dev"
    "L+ /var/www/gatlinburg2026.dcbond.com - - - - /var/lib/nextcloud/data/Chris\\040Bond/files/Bond\\040Family/Travel/2026/April\\040-\\040Gatlinburg\\040TN/gatlinburg2026.dcbond.com"
  ];

  services = {

    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {

        "weekly-recipes.${configVars.domain2}" = {
          enableACME = false;
          forceSSL = false;
          root = "/var/www/weekly-recipes.opticon.dev";
          listen = [
            {
              addr = "127.0.0.1";
              port = 9016;
            }
          ];
        };

        "gatlinburg2026.${configVars.domain1}" = {
          enableACME = false;
          forceSSL = false;
          root = "/var/www/gatlinburg2026.dcbond.com";
          listen = [
            {
              addr = "127.0.0.1";
              port = 9017;
            }
          ];
        };

        "maintenance-page" = {
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

      };
    };

    authelia.instances."${configVars.domain1Short}".settings.access_control.rules = [
      {
        domain = [ "gatlinburg2026.${configVars.domain1}" ];
        subject = [
          "user:admin"
          "user:danielle-bond"
          "user:guest"
        ];
        policy = "one_factor";
      }
    ];
       
    traefik = {

      dynamicConfigOptions.http = {

        middlewares = {
          error-pages = {
            errors = {
              status = ["502" "503" "504"];
              service = "maintenance-page";
              query = "/";
            };
          };
        };

        routers = {

          "weekly-recipes" = {
            entrypoints = ["websecure"];
            rule = "Host(`weekly-recipes.${configVars.domain2}`)";
            service = "weekly-recipes";
            middlewares = [
              "trusted-allow"
              "secure-headers"
            ];
            tls = {
              certResolver = "cloudflareDns";
              options = "tls-13@file";
            };
          };

          "gatlinburg2026" = {
            entrypoints = ["websecure"];
            rule = "Host(`gatlinburg2026.${configVars.domain1}`)";
            service = "gatlinburg2026";
            middlewares = [
              "authelia-dcbond"
              "secure-headers"
            ];
            tls = {
              certResolver = "cloudflareDns";
              options = "tls-13@file";
            };
          };
        };

        services = {

          "weekly-recipes" = {
            loadBalancer = {
              passHostHeader = true;
              servers = [
                {
                  url = "http://127.0.0.1:9016";
                }
              ];
            };
          };

          "gatlinburg2026" = {
            loadBalancer = {
              passHostHeader = true;
              servers = [
                {
                  url = "http://127.0.0.1:9017";
                }
              ];
            };
          };

          "maintenance-page" = {
            loadBalancer = {
              servers = [
                {
                  url = "http://127.0.0.1:9018";
                }
              ];
            };
          };

        };
      };
    };

  };

}