{
  pkgs,
  config,
  lib,
  configVars,
  ...
}: 

{

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = lib.optionals (!config.hostSpecificConfigs.isMonitoringServer) [ 
    9100 # prometheus node exporter
    9633 # smartctl exporter
  ]; # monitoring-server needs to connect to these ports on monitoring-clients

  services = {
    
    prometheus.exporters = {
      node = {
        enable = true;
        port = 9100;
        listenAddress = if config.hostSpecificConfigs.isMonitoringServer
          then "127.0.0.1" # local scraping on monitoring server
          else "0.0.0.0"; # remote scraping from monitoring server
        enabledCollectors = [ 
          "systemd" # service states and health
          "processes" # process count, states, forks
          "interrupts" # irq statistics
          "tcpstat"  # tcp connection states
          "buddyinfo"  # memory fragmentation
        ];
      };
      smartctl = {
        enable = true;
        port = 9633;
        maxInterval = "60s";
      };
    };

    smartd = {
      enable = true;
      autodetect = true;
      notifications.wall.enable = false;
    };

    promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 3031;
          grpc_listen_port = 0;
        };
        clients = [{
          url = if config.hostSpecificConfigs.isMonitoringServer
            then "http://127.0.0.1:3030/loki/api/v1/push"
            else "http://${configVars.aspenTailscaleIp}:3030/loki/api/v1/push";
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
        ] ++ lib.optionals config.services.traefik.enable [
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

  };

}