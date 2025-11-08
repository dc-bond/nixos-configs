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
        enabledCollectors = [ 
          "systemd" # service states and health
          "processes" # process count, states, forks
          "interrupts" # irq statistics
          "tcpstat"  # tcp connection states
          "buddyinfo"  # memory fragmentation
        ];
      };
      scrapeConfigs = [
        {
          job_name = "nodes";
          static_configs = [
            {
              targets = [ "127.0.0.1:9100" ];
              labels.host = "aspen";
            }
            {
              targets = [ "${configVars.cypressTailscaleIp}:9100" ];
              labels.host = "cypress";
            }
            {
              targets = [ "${configVars.thinkpadTailscaleIp}:9100" ];
              labels.host = "thinkpad";
            }
            {
              targets = [ "${configVars.juniperTailscaleIp}:9100" ];
              labels.host = "juniper";
            }
          ];
        }
        {
          job_name = "traefik";
          static_configs = [
            {
              targets = [ "127.0.0.1:9100" ];
              labels.host = "aspen";
            }
            {
              targets = [ "${configVars.juniperTailscaleIp}:9100" ];
              labels.host = "juniper";
            }
          ];
        }
      ];
    };

    ${app} = {
      enable = true;
      settings.server = {
        http_addr = "127.0.0.1";
        http_port = 3002;
        domain = "${app}.${configVars.domain2}";
        root_url = "https://${app}.${configVars.domain2}";
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
        rule = "Host(`${app}.${configVars.domain2}`)";
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
            url = "http://127.0.0.1:3002";
          }];
        };
      };
    };

  };

}