{
  pkgs,
  config,
  lib,
  configVars,
  ...
}: 

let
  app = "grafana";
in

{

  services = {

    prometheus = {
      enable = true;
      port = 9090;
      exporters.node = {
        enable = true;
        port = 9100;
        enabledCollectors = [ "systemd" ];
      };
      scrapeConfigs = [
        {
          job_name = "local-node";
          static_configs = [{
            targets = [ "localhost:9100" ];
          }];
        }
      ];
    };

    grafana = {
      enable = true;
      settings.server = {
        http_addr = "127.0.0.1";
        http_port = 3001;
        domain = "grafana.${configVars.domain2}";
        root_url = "https://grafana.${configVars.domain2}";
      };
      provision = {
        enable = true;
        datasources.settings.datasources = [{
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:9090";
          isDefault = true;
        }];
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`grafana.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [
          "secure-headers"
          "trusted-allow"
        ];
        tls = {
          certResolver = "cloudflareDns";
          options = "tls-13@file";
        };
      };
      services.${app} = {
        loadBalancer = {
          passHostHeader = true;
          servers = [{
            url = "http://127.0.0.1:3001";
          }];
        };
      };
    };

  };

}