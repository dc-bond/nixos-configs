{
  pkgs,
  config,
  lib,
  configVars,
  nixServiceRecoveryScript,
  ...
}:

let
  app1 = "prometheus";
  app2 = "grafana";
  app3 = "alertmanager";
  app4 = "loki";

  recoveryPlan = {
    restoreItems = [
      "/var/lib/${app2}"
    ];
    stopServices = [ "${app2}" ];
    startServices = [ "${app2}" ];
  };

  recoverScript = nixServiceRecoveryScript {
    serviceName = app2;
    recoveryPlan = recoveryPlan;
  };

  # transformer service that converts alertmanager webhooks to matrix hookshot format
  transformerScript = pkgs.writeText "alertmanager-transformer.py" ''
    #!/usr/bin/env python3
    from http.server import BaseHTTPRequestHandler, HTTPServer
    import json
    import os
    import urllib.request
    import urllib.error

    HOOKSHOT_URL = os.environ.get("HOOKSHOT_URL", "")
    PORT = int(os.environ.get("PORT", "9099"))

    def format_alert(alert):
        severity = alert.get("labels", {}).get("severity", "unknown")
        alertname = alert.get("labels", {}).get("alertname", "Unknown Alert")
        instance = alert.get("labels", {}).get("instance") or alert.get("labels", {}).get("host", "unknown")
        description = alert.get("annotations", {}).get("description") or alert.get("annotations", {}).get("summary", "No description")

        emoji = "🔴" if severity == "critical" else "⚠️"
        return f"{emoji} **{alertname}** ({severity})\n📍 {instance}\n{description}"

    class AlertmanagerHandler(BaseHTTPRequestHandler):
        def log_message(self, format, *args):
            # Log to stdout for journald
            print(f"{self.address_string()} - {format % args}")

        def do_POST(self):
            try:
                content_length = int(self.headers["Content-Length"])
                body = self.rfile.read(content_length)
                data = json.loads(body.decode("utf-8"))

                # Transform Alertmanager payload to Hookshot format
                status = "🔴 **FIRING**" if data.get("status") == "firing" else "✅ **RESOLVED**"
                alert_count = len(data.get("alerts", []))

                alerts = [format_alert(alert) for alert in data.get("alerts", [])]
                alerts_text = "\n\n---\n\n".join(alerts)

                message = f"{status} - {alert_count} alert(s)\n\n{alerts_text}"

                # Send to Hookshot
                hookshot_payload = json.dumps({"text": message}).encode("utf-8")
                req = urllib.request.Request(
                    HOOKSHOT_URL,
                    data=hookshot_payload,
                    headers={"Content-Type": "application/json"}
                )

                with urllib.request.urlopen(req, timeout=10) as response:
                    self.send_response(response.status)
                    self.end_headers()
                    self.wfile.write(response.read())

            except Exception as e:
                print(f"Error processing webhook: {e}")
                self.send_response(500)
                self.end_headers()
                self.wfile.write(f"Error: {str(e)}".encode("utf-8"))

    if __name__ == "__main__":
        if not HOOKSHOT_URL:
            print("ERROR: HOOKSHOT_URL environment variable not set")
            exit(1)

        server = HTTPServer(("127.0.0.1", PORT), AlertmanagerHandler)
        print(f"Alertmanager to Hookshot transformer listening on 127.0.0.1:{PORT}")
        print(f"Forwarding to: {HOOKSHOT_URL}")
        server.serve_forever()
  '';

  alertRules = pkgs.writeText "alert-rules.yml" ''
    groups:

      - name: endpoint_health_alerts
        interval: 30s
        rules:

          - alert: PublicEndpointDown
            expr: probe_success{job="blackbox-http"} == 0
            for: 3m
            labels:
              severity: critical
            annotations:
              summary: "Public endpoint {{ $labels.instance }} is unreachable"
              description: "HTTP(S) probe to {{ $labels.instance }} has been failing for more than 3 minutes."

          - alert: SSLCertificateExpiringSoon
            expr: (probe_ssl_earliest_cert_expiry - time()) / 86400 < 14
            for: 1h
            labels:
              severity: warning
            annotations:
              summary: "SSL certificate for {{ $labels.instance }} expires in {{ $value | humanizeDuration }}"
              description: "SSL certificate for {{ $labels.instance }} will expire in less than 14 days."

          - alert: SSLCertificateExpired
            expr: probe_ssl_earliest_cert_expiry - time() < 0
            for: 1m
            labels:
              severity: critical
            annotations:
              summary: "SSL certificate for {{ $labels.instance }} has expired"
              description: "SSL certificate for {{ $labels.instance }} is expired."

      - name: host_health_alerts
        interval: 30s
        rules:

          - alert: HostDown
            expr: up{job="node"} == 0
            for: 3m
            labels:
              severity: critical
            annotations:
              summary: "Host {{ $labels.host }} is unreachable"
              description: "Prometheus cannot scrape metrics from {{ $labels.host }} for more than 3 minutes."

          - alert: HighCPUUsage
            expr: 100 - (avg by (host) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
            for: 10m
            labels:
              severity: warning
            annotations:
              summary: "High CPU usage on {{ $labels.host }}"
              description: "CPU usage on {{ $labels.host }} has been above 90% for more than 10 minutes."

          - alert: HighMemoryUsage
            expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "High memory usage on {{ $labels.host }}"
              description: "Memory usage on {{ $labels.host }} has been above 90% for more than 5 minutes."

          - alert: DiskSpaceLow
            expr: (node_filesystem_avail_bytes{fstype=~"ext4|btrfs|xfs"} / node_filesystem_size_bytes{fstype=~"ext4|btrfs|xfs"}) * 100 < 10
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "Disk space low on {{ $labels.host }}:{{ $labels.mountpoint }}"
              description: "Filesystem {{ $labels.mountpoint }} on {{ $labels.host }} has less than 10% free space remaining."

          - alert: DiskSpaceCritical
            expr: (node_filesystem_avail_bytes{fstype=~"ext4|btrfs|xfs"} / node_filesystem_size_bytes{fstype=~"ext4|btrfs|xfs"}) * 100 < 5
            for: 2m
            labels:
              severity: critical
            annotations:
              summary: "Disk space critical on {{ $labels.host }}:{{ $labels.mountpoint }}"
              description: "Filesystem {{ $labels.mountpoint }} on {{ $labels.host }} has less than 5% free space remaining."
  '';

in

{

  users = {
    users.${app3} = {
      isSystemUser = true;
      group = "${app3}";
    };
    groups.${app3} = {};
  };

  sops = {
    secrets.chrisNotificationsWebhookUrl = {};
    templates."alertmanager-hookshot-env".content = ''
      HOOKSHOT_URL=${config.sops.placeholder.chrisNotificationsWebhookUrl}
    '';
  };

  systemd.services.alertmanager-to-hookshot = {
    description = "Alertmanager to Matrix Hookshot Transformer";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.python3}/bin/python3 ${transformerScript}";
      Restart = "on-failure";
      RestartSec = "10s";
      EnvironmentFile = config.sops.templates."alertmanager-hookshot-env".path;
      Environment = [ "PORT=9099" ];
      DynamicUser = true;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunels = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      RestrictNamespaces = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      PrivateMounts = true;
    };
  };

  services = {

    smartd = lib.mkIf (configVars.hosts.${config.networking.hostName}.hardware.enableSmartMonitoring or false) {
      enable = true;
      autodetect = true;
      notifications.wall.enable = false;
    };

    cadvisor = lib.mkIf (config.virtualisation.oci-containers.containers != {}) {
      enable = true;
      port = 7541;
      listenAddress = "127.0.0.1";
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

    prometheus = {
      enable = true;
      port = 9090;
      globalConfig.scrape_interval = "15s";
      ruleFiles = [ alertRules ];
      alertmanagers = [{
        static_configs = [{
          targets = [ "127.0.0.1:9093" ];
        }];
      }];

      scrapeConfigs = [ # tells prometheus which services to scrape metrics from and which hosts (itself or others) it should scrape those metrics from
        {
          job_name = "node";
          static_configs = [
            {
              targets = [ "127.0.0.1:9100" ];
              labels.host = config.networking.hostName;
            }
            {
              targets = [ "${configVars.hosts.aspen.networking.tailscaleIp}:9100" ];
              labels.host = "aspen";
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
              targets = [ "${configVars.hosts.alder.networking.tailscaleIp}:9100" ];
              labels.host = "alder";
            }
            {
              targets = [ "${configVars.hosts.kauri.networking.tailscaleIp}:9100" ];
              labels.host = "kauri";
            }
          ];
        }
        {
          job_name = "smartctl"; # juniper on vps so no smart monitoring
          static_configs = [
            #{
            #  targets = [ "127.0.0.1:9633" ];
            #  labels.host = config.networking.hostName;
            #}
            {
              targets = [ "${configVars.hosts.aspen.networking.tailscaleIp}:9633" ];
              labels.host = "aspen";
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
              targets = [ "${configVars.hosts.alder.networking.tailscaleIp}:9633" ];
              labels.host = "alder";
            }
            {
              targets = [ "${configVars.hosts.kauri.networking.tailscaleIp}:9633" ];
              labels.host = "kauri";
            }
          ];
        }
        {
          job_name = "traefik";
          static_configs = [
            {
              targets = [ "${configVars.hosts.aspen.networking.tailscaleIp}:8082" ];
              labels.host = "aspen";
            }
            {
              targets = [ "127.0.0.1:8082" ];
              labels.host = config.networking.hostName;
            }
          ];
        }
        {
          job_name = "crowdsec";
          static_configs = [
            {
              targets = [ "${configVars.hosts.aspen.networking.tailscaleIp}:6060" ];
              labels.host = "aspen";
            }
            {
              targets = [ "127.0.0.1:6060" ];
              labels.host = config.networking.hostName;
            }
          ];
        }
        {
          job_name = "cadvisor";
          static_configs = [
            {
              targets = [ "${configVars.hosts.aspen.networking.tailscaleIp}:7541" ];
              labels.host = "aspen";
            }
            {
              targets = [ "127.0.0.1:7541" ];
              labels.host = config.networking.hostName;
            }
          ];
        }
        {
          job_name = "blackbox-http";
          metrics_path = "/probe";
          params.module = [ "https_2xx" ];
          static_configs = [
            {
              targets = [
                # aspen services
                "https://nextcloud.${configVars.domain1}"
                "https://identity.${configVars.domain1}"
                # juniper services
                "https://matrix.${configVars.domain1}"
                "https://vaultwarden.${configVars.domain1}"
                "https://grafana.${configVars.domain2}"
                "https://homepage.${configVars.domain2}"
              ];
            }
          ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              target_label = "__address__";
              replacement = "127.0.0.1:9115";
            }
          ];
        }
      ];

      # local exporters for monitoring server itself
      exporters = {
        node = {
          enable = true;
          port = 9100;
          listenAddress = "127.0.0.1"; # local scraping only
          enabledCollectors = [
            "systemd"
            "processes"
            "interrupts"
            "tcpstat"
            "buddyinfo"
          ];
        };
        smartctl = lib.mkIf (configVars.hosts.${config.networking.hostName}.hardware.enableSmartMonitoring or false) {
          enable = true;
          port = 9633;
          listenAddress = "127.0.0.1";
          maxInterval = "60s";
        };
        blackbox = {
          enable = true;
          port = 9115;
          listenAddress = "127.0.0.1";
          configFile = pkgs.writeText "blackbox.yml" ''
            modules:
              http_2xx:
                prober: http
                timeout: 10s
                http:
                  valid_status_codes: [200, 201, 202, 204, 301, 302, 307, 308]
                  method: GET
                  preferred_ip_protocol: "ip4"
                  follow_redirects: true
                  fail_if_ssl: false
                  fail_if_not_ssl: false
                  tls_config:
                    insecure_skip_verify: false
              https_2xx:
                prober: http
                timeout: 10s
                http:
                  valid_status_codes: [200, 201, 202, 204, 301, 302, 307, 308]
                  method: GET
                  preferred_ip_protocol: "ip4"
                  follow_redirects: true
                  fail_if_ssl: false
                  fail_if_not_ssl: true
                  tls_config:
                    insecure_skip_verify: false
          '';
        };
      
      };

      alertmanager = {
        enable = true;
        port = 9093;
        listenAddress = "127.0.0.1";
        webExternalUrl = "https://${app3}.${configVars.domain2}";
        configuration = {
          global = {
            resolve_timeout = "5m";
          };
          route = {
            receiver = "matrix-webhook";
            group_by = [ "alertname" "host" "severity" ];
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "4h";
          };
          receivers = [
            {
              name = "matrix-webhook";
              webhook_configs = [
                {
                  url = "http://127.0.0.1:9099"; # Local transformer service
                  send_resolved = true;
                  http_config = {
                    follow_redirects = true;
                  };
                }
              ];
            }
          ];
          inhibit_rules = [
            # inhibit warning if critical is firing
            {
              source_matchers = [ "severity=critical" ];
              target_matchers = [ "severity=warning" ];
              equal = [ "alertname" "host" ];
            }
            # inhibit endpoint down if host is down
            {
              source_matchers = [ "alertname=HostDown" ];
              target_matchers = [ "alertname=PublicEndpointDown" ];
              equal = [ "host" ];
            }
          ];
        };
      };

    };

    loki = {
      enable = true;
      configuration = {
        auth_enabled = false;
        server = {
          http_listen_port = 3030;
          http_listen_address = "127.0.0.1";
        };
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

    ${app2} = {
      enable = true;
      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = 3002;
          domain = "${app2}.${configVars.domain2}";
          root_url = "https://${app2}.${configVars.domain2}";
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
      routers.${app1} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app1}.${configVars.domain2}`)";
        service = "${app1}";
        middlewares = [
          "secure-headers"
          "trusted-allow"
        ];
        tls = {
          certResolver = "cloudflareDns";
          options = "tls-13@file";
        };
      };
      services.${app1} = {
        loadBalancer = {
          passHostHeader = true;
          servers = [{
            url = "http://127.0.0.1:9090";
          }];
        };
      };

      routers.${app2} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app2}.${configVars.domain2}`)";
        service = "${app2}";
        middlewares = [
          "secure-headers"
          "trusted-allow"
        ];
        tls = {
          certResolver = "cloudflareDns";
          options = "tls-13@file";
        };
      };
      services.${app2} = {
        loadBalancer = {
          passHostHeader = true;
          servers = [{
            url = "http://127.0.0.1:3002";
          }];
        };
      };

      routers.${app3} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app3}.${configVars.domain2}`)";
        service = "${app3}";
        middlewares = [
          "secure-headers"
          "trusted-allow"
        ];
        tls = {
          certResolver = "cloudflareDns";
          options = "tls-13@file";
        };
      };
      services.${app3} = {
        loadBalancer = {
          passHostHeader = true;
          servers = [{
            url = "http://127.0.0.1:9093";
          }];
        };
      };

    };

    borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;

  };

  environment.systemPackages = with pkgs; [ recoverScript ];

  backups.serviceHooks = {
    preHook = lib.mkAfter [
      "systemctl stop ${app2}.service"
    ];
    postHook = lib.mkAfter [
      "systemctl start ${app2}.service"
    ];
  };

}