{
  pkgs,
  config,
  lib,
  configVars,
  ...
}: 

{

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9100 ]; # open prometheus node exporter port on tailscale interface to allow monitoring-server to scrape data (server needs to connect to client's node exporter port)

  services = {
    
    prometheus.exporters = {
      node = {
        enable = true;
        port = 9100;
        listenAddress = "0.0.0.0";  # listen on all interfaces, tailscale included, because remote monitoring-server needs to scrape from afar
        enabledCollectors = [ 
          "systemd" # service states and health
          "processes" # process count, states, forks
          "interrupts" # irq statistics
          "tcpstat"  # tcp connection states
          "buddyinfo"  # memory fragmentation
        ];
      };
      #smartctl = {
      #  enable = true;
      #  port = 9633;
      #  devices = [
      #    "/dev/nvme0n1"
      #    "/dev/sda"
      #  ];
      #  maxInterval = "60s";
      #};
    };

    promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 3031;
          grpc_listen_port = 0;
        };
        clients = [{
          url = "http://${configVars.aspenTailscaleIp}:3030/loki/api/v1/push";
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
        ] ++ lib.optionals (config.networking.hostName == "juniper") [
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