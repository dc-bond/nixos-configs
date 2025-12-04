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

  #networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 3030 ]; # open loki port on tailscale interface to recieve logs pushed from other monitoring-clients (clients need to connect to server's loki port)

  services = {

    prometheus = {
      enable = true;
      port = 9090;
      globalConfig.scrape_interval = "15s";
      scrapeConfigs = [ # tells prometheus on monitoring-server which services to scrape metrics from and which hosts (itself or others) it should scrape those metrics from
        {
          job_name = "node";
          static_configs = [
            {
              targets = [ "127.0.0.1:9100" ];
              labels.host = config.networking.hostName;
            }
            {
              targets = [ "${configVars.hosts.cypress.networking.tailscaleIp}:9100" ];
              labels.host = "cypress";
            }
            {
              targets = [ "${configVars.hosts.thinkpad.networking.tailscaleIp}:9100" ];
              labels.host = "thinkpad";
            }
            {
              targets = [ "${configVars.hosts.juniper.networking.tailscaleIp}:9100" ];
              labels.host = "juniper";
            }
            {
              targets = [ "${configVars.hosts.alder.networking.tailscaleIp}:9100" ];
              labels.host = "alder";
            }
          ];
        }
        {
          job_name = "smartctl";
          static_configs = [
            {
              targets = [ "127.0.0.1:9633" ];
              labels.host = config.networking.hostName;
            }
            {
              targets = [ "${configVars.hosts.cypress.networking.tailscaleIp}:9633" ];
              labels.host = "cypress";
            }
            {
              targets = [ "${configVars.hosts.thinkpad.networking.tailscaleIp}:9633" ];
              labels.host = "thinkpad";
            }
            {
              targets = [ "${configVars.hosts.alder.networking.tailscaleIp}:9100" ];
              labels.host = "alder";
            }
          ];
        }
        {
          job_name = "traefik";
          static_configs = [
            {
              targets = [ "127.0.0.1:8082" ];
              labels.host = config.networking.hostName;
            }
            {
              targets = [ "${configVars.hosts.juniper.networking.tailscaleIp}:8082" ];
              labels.host = "juniper";
            }
          ];
        }
        {
          job_name = "crowdsec";
          static_configs = [
            {
              targets = [ "127.0.0.1:6060" ];
              labels.host = config.networking.hostName;
            }
            {
              targets = [ "${configVars.hosts.juniper.networking.tailscaleIp}:6060" ];
              labels.host = "juniper";
            }
          ];
        }
        {
          job_name = "cadvisor";
          static_configs = [
            {
              targets = [ "127.0.0.1:7541" ];
              labels.host = config.networking.hostName;
            }
          ];
        }
      ];
    };

    loki = {
      enable = true;
      configuration = {
        auth_enabled = false;
        server.http_listen_port = 3030;
        common = {
          ring = {
            instance_addr = "127.0.0.1";
            kvstore.store = "inmemory";
          };
          replication_factor = 1;
          path_prefix = "/var/lib/loki";
        };
        schema_config.configs = [{
          from = "2024-04-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }];
        storage_config.filesystem.directory = "/var/lib/loki/chunks";
        limits_config = {
          retention_period = "168h";
          ingestion_rate_mb = 16; # default is 4MB/sec
          ingestion_burst_size_mb = 32; # default is 6MB
        };
        compactor = {
          working_directory = "/var/lib/loki/compactor";
          compaction_interval = "10m";
          retention_enabled = true;
          retention_delete_delay = "2h";
          retention_delete_worker_count = 150;
          delete_request_store = "filesystem";
        };
      };
    };

    ${app} = {
      enable = true;
      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = 3002;
          domain = "${app}.${configVars.domain2}";
          root_url = "https://${app}.${configVars.domain2}";
        };
        news.news_feed_enabled = false;
        analytics = {
          reporting_enabled = false;
          check_for_updates = false;
          check_for_plugin_updates = false;
        };
      };
      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://127.0.0.1:9090";
            isDefault = true;
          }
          {
            name = "Loki";
            type = "loki";
            url = "http://127.0.0.1:3030";
          }
        ];
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