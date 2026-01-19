{
  pkgs,
  config,
  lib,
  configVars,
  ...
}:

let
  hostData = configVars.hosts.${config.networking.hostName};
in

{

  services = {

    smartd = lib.mkIf (hostData.hardware.enableSmartMonitoring or false) {
      enable = true;
      autodetect = true;
      notifications.wall.enable = false;
    };

    cadvisor = lib.mkIf (config.virtualisation.oci-containers.containers != {}) {
      enable = true;
      port = 7541;
      listenAddress = hostData.networking.tailscaleIp;
    };

    prometheus.exporters = {
      node = {
        enable = true;
        port = 9100;
        listenAddress = hostData.networking.tailscaleIp; # bind to tailscale interface for secure remote scraping
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
        listenAddress = hostData.networking.tailscaleIp;
        maxInterval = "60s";
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
          url = "http://${configVars.hosts.juniper.networking.tailscaleIp}:3030/loki/api/v1/push";
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