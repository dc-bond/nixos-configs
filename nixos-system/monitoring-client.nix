{
  pkgs,
  config,
  lib,
  configVars,
  ...
}: 

let
  hostData = configVars.hosts.${config.networking.hostName};
  monitoringServer = lib.findFirst 
    (h: h.isMonitoringServer) 
    null 
    (lib.attrValues configVars.hosts);
in

{

  services = {
    
    prometheus.exporters = {
      node = {
        enable = true;
        port = 9100;
        listenAddress = if hostData.isMonitoringServer
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
      smartctl = lib.mkIf (hostData.hardware.enableSmartMonitoring or false) {
        enable = true;
        port = 9633;
        listenAddress = if hostData.isMonitoringServer
          then "127.0.0.1"
          else "0.0.0.0";
        maxInterval = "60s";
      };
    };

    smartd = lib.mkIf (hostData.hardware.enableSmartMonitoring or false) {
      enable = true;
      autodetect = true;
      notifications.wall.enable = false;
    };

    cadvisor = lib.mkIf (config.virtualisation.oci-containers.containers != {}) {
      enable = true;
      port = 7541;
      listenAddress = if hostData.isMonitoringServer
        then "127.0.0.1"
        else "0.0.0.0";
    };

    promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 3031;
          grpc_listen_port = 0;
        };
        clients = [{
          url = if hostData.isMonitoringServer
            then "http://127.0.0.1:3030/loki/api/v1/push"
            else "http://${monitoringServer.networking.tailscaleIp}:3030/loki/api/v1/push";
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