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
              targets = [ "127.0.0.1:8082" ];
              labels.host = "aspen";
            }
            {
              targets = [ "${configVars.juniperTailscaleIp}:8082" ];
              labels.host = "juniper";
            }
          ];
        }
        {
          job_name = "crowdsec";
          static_configs = [
            {
              targets = [ "127.0.0.1:6060" ];
              labels.host = "aspen";
            }
            {
              targets = [ "${configVars.juniperTailscaleIp}:6060" ];
              labels.host = "juniper";
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
        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring.kvstore.store = "inmemory";
            final_sleep = "0s";
          };
          chunk_idle_period = "5m";
          chunk_retain_period = "30s";
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
        storage_config = {
          tsdb_shipper = {
            active_index_directory = "/var/lib/loki/tsdb-index";
            cache_location = "/var/lib/loki/tsdb-cache";
          };
          filesystem.directory = "/var/lib/loki/chunks";
        };
        limits_config.retention_period = "168h"; # 7 days
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

    promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 3031;
          grpc_listen_port = 0;
        };
        clients = [{
          url = "http://127.0.0.1:3030/loki/api/v1/push";
        }];
        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              labels.host = config.networking.hostName;
            };
            relabel_configs = [{
              source_labels = ["__journal__systemd_unit"];
              target_label = "unit";
            }];
          }
          {
            job_name = "traefik";
            static_configs = [{
              targets = [ "127.0.0.1" ];
              labels = {
                job = "traefik";
                host = config.networking.hostName;
                __path__ = "/var/log/traefik/access.log";
              };
            }];
            pipeline_stages = [{
              json.expressions = {
                status = "DownstreamStatus";
                method = "RequestMethod";
                path = "RequestPath";
                client_ip = "ClientHost";
              };
            }];
          }
        ];
      };
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