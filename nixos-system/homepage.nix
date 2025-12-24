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
        "Services" = [
          {
            "Example Service" = {
              href = "https://example.com";
              description = "Example service description";
              icon = "mdi-home";
            };
          }
        ];
      }
    ];

    bookmarks = [
      {
        "Development" = [
          {
            "Github" = [
              {
                abbr = "GH";
                href = "https://github.com";
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

    # Uncomment and configure as needed:
    # docker = {};
    # kubernetes = {};
    # proxmox = {};
    # customCSS = "";
    # customJS = "";
    # environmentFile = null;
    # allowedHosts = [];
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
