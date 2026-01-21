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

  # weekly disk health report generator
  weeklyDiskHealthScript = pkgs.writeText "weekly-disk-health.py" ''
    #!/usr/bin/env python3
    import json
    import urllib.request
    import urllib.error
    import os
    from datetime import datetime

    PROMETHEUS_URL = "http://127.0.0.1:9090"
    WEBHOOK_URL = os.environ.get("WEBHOOK_URL", "")

    def query_prometheus(query):
        """Query Prometheus and return results"""
        url = f"{PROMETHEUS_URL}/api/v1/query?query={urllib.parse.quote(query)}"
        try:
            with urllib.request.urlopen(url, timeout=10) as response:
                data = json.loads(response.read().decode("utf-8"))
                if data["status"] == "success":
                    return data["data"]["result"]
        except Exception as e:
            print(f"Error querying Prometheus: {e}")
        return []

    def format_hours(hours):
        """Convert hours to years, months, days"""
        years = int(hours / 8760)
        remaining = hours % 8760
        months = int(remaining / 730)
        days = int((remaining % 730) / 24)

        parts = []
        if years > 0:
            parts.append(f"{years}y")
        if months > 0:
            parts.append(f"{months}m")
        if days > 0:
            parts.append(f"{days}d")
        return " ".join(parts) if parts else "0d"

    def get_disk_inventory():
        """Get list of all disks and basic info"""
        results = query_prometheus('smartctl_device')
        disks = {}
        for result in results:
            labels = result["metric"]
            device = labels.get("device", "unknown")
            host = labels.get("host", "unknown")
            key = f"{host}:{device}"
            disks[key] = {
                "host": host,
                "device": device,
                "model": labels.get("model_name", "unknown"),
                "serial": labels.get("serial_number", "unknown"),
                "interface": labels.get("interface", "unknown"),
            }
        return disks

    def get_smart_status(host, device):
        """Get overall SMART status"""
        results = query_prometheus(f'smartctl_device_smart_status{{host="{host}",device="{device}"}}')
        if results:
            return "PASSED" if int(results[0]["value"][1]) == 1 else "FAILED"
        return "UNKNOWN"

    def get_temperature(host, device):
        """Get current temperature"""
        results = query_prometheus(f'smartctl_device_temperature{{host="{host}",device="{device}",temperature_type="current"}}')
        if results:
            return int(results[0]["value"][1])
        return None

    def get_attribute_value(host, device, attr_name):
        """Get raw value of a SMART attribute"""
        results = query_prometheus(
            f'smartctl_device_attribute{{host="{host}",device="{device}",attribute_name="{attr_name}",attribute_value_type="raw"}}'
        )
        if results:
            return int(float(results[0]["value"][1]))
        return None

    def generate_report():
        """Generate comprehensive disk health report"""
        disks = get_disk_inventory()

        if not disks:
            return "⚠️ No disks found in monitoring system"

        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        # Header
        report = f"📊 **Weekly Disk Health Report**\\n\\n"
        report += f"**Generated**: {timestamp}\\n"
        report += f"**Total Disks**: {len(disks)}\\n\\n"

        # Overall health summary
        failed_disks = []
        warning_disks = []

        for key, disk in disks.items():
            status = get_smart_status(disk["host"], disk["device"])
            if status == "FAILED":
                failed_disks.append(f"{disk['host']}:{disk['device']}")

            # Check for warning conditions
            reallocated = get_attribute_value(disk["host"], disk["device"], "Reallocated_Sector_Ct")
            pending = get_attribute_value(disk["host"], disk["device"], "Current_Pending_Sector")
            temp = get_temperature(disk["host"], disk["device"])

            if (reallocated and reallocated > 0) or (pending and pending > 0) or (temp and temp > 50):
                warning_disks.append(f"{disk['host']}:{disk['device']}")

        if failed_disks:
            report += f"🔴 **CRITICAL**: {len(failed_disks)} disk(s) with FAILED SMART status\\n"
            for disk in failed_disks:
                report += f"   • {disk}\\n"
            report += "\\n"

        if warning_disks:
            report += f"⚠️ **WARNING**: {len(warning_disks)} disk(s) with warning conditions\\n"
            for disk in warning_disks:
                report += f"   • {disk}\\n"
            report += "\\n"

        if not failed_disks and not warning_disks:
            report += "✅ **All disks healthy**\\n\\n"

        report += "---\\n\\n"

        # Detailed per-disk report
        for key, disk in sorted(disks.items()):
            host = disk["host"]
            device = disk["device"]

            report += f"**{host} - {device}**\\n"
            report += f"Model: {disk['model'][:40]}\\n"

            # SMART status
            status = get_smart_status(host, device)
            status_emoji = "✅" if status == "PASSED" else "🔴"
            report += f"Status: {status_emoji} {status}\\n"

            # Temperature
            temp = get_temperature(host, device)
            if temp is not None:
                temp_emoji = "🌡️" if temp <= 50 else "🔥"
                report += f"Temp: {temp_emoji} {temp}°C\\n"

            # Power-on hours
            hours = get_attribute_value(host, device, "Power_On_Hours")
            if hours is not None:
                runtime = format_hours(hours)
                report += f"Runtime: {runtime} ({hours:,} hours)\\n"

            # Critical attributes
            reallocated = get_attribute_value(host, device, "Reallocated_Sector_Ct")
            pending = get_attribute_value(host, device, "Current_Pending_Sector")
            uncorrectable = get_attribute_value(host, device, "Offline_Uncorrectable")

            if reallocated is not None and reallocated > 0:
                report += f"⚠️ Reallocated Sectors: {reallocated}\\n"
            if pending is not None and pending > 0:
                report += f"🔴 Pending Sectors: {pending}\\n"
            if uncorrectable is not None and uncorrectable > 0:
                report += f"🔴 Uncorrectable Sectors: {uncorrectable}\\n"

            report += "\\n"

        return report

    def send_webhook(message):
        """Send report to Matrix via webhook"""
        if not WEBHOOK_URL:
            print("ERROR: WEBHOOK_URL not set")
            return False

        payload = json.dumps({"text": message}).encode("utf-8")
        req = urllib.request.Request(
            WEBHOOK_URL,
            data=payload,
            headers={"Content-Type": "application/json"}
        )

        try:
            with urllib.request.urlopen(req, timeout=10) as response:
                return response.status == 200
        except Exception as e:
            print(f"Error sending webhook: {e}")
            return False

    if __name__ == "__main__":
        report = generate_report()
        print(report)

        if send_webhook(report):
            print("\\nReport sent successfully")
        else:
            print("\\nFailed to send report")
  '';

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
        alertname = alert.get("labels", {}).get("alertname", "Unknown Alert")
        # Use host label for node alerts, fall back to instance for endpoint alerts
        identifier = alert.get("labels", {}).get("host") or alert.get("labels", {}).get("instance", "unknown")

        return f"**{alertname}** ({identifier})"

    class AlertmanagerHandler(BaseHTTPRequestHandler):
        def log_message(self, format, *args):
            print(f"{self.address_string()} - {format % args}")

        def do_POST(self):
            try:
                content_length = int(self.headers["Content-Length"])
                body = self.rfile.read(content_length)
                data = json.loads(body.decode("utf-8"))

                status = "🔴 **FIRING**" if data.get("status") == "firing" else "✅ **RESOLVED**"
                alert_count = len(data.get("alerts", []))

                alerts = [format_alert(alert) for alert in data.get("alerts", [])]
                alerts_text = "\n\n---\n\n".join(alerts)

                message = f"{status} - {alert_count} alert(s)\n\n{alerts_text}"

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

          - alert: publicEndpointDown
            expr: probe_success{job="blackbox-http"} == 0
            for: 1m
            labels:
              severity: critical
            annotations:
              summary: "{{ $labels.instance }} is down (probe failed)"

          - alert: sslCertificateExpiringSoon
            expr: (probe_ssl_earliest_cert_expiry - time()) / 86400 < 14
            for: 1h
            labels:
              severity: warning

          - alert: sslCertificateExpired
            expr: probe_ssl_earliest_cert_expiry - time() < 0
            for: 1m
            labels:
              severity: critical

      - name: host_health_alerts
        interval: 30s
        rules:

          - alert: hostDown
            expr: up{job="node", host=~"aspen|juniper|cypress|kauri"} == 0
            for: 2m
            labels:
              severity: critical

          - alert: hostUp
            expr: up{job="node", host=~"thinkpad|alder"} == 1 and up{job="node", host=~"thinkpad|alder"} offset 5m == 0
            for: 1m
            labels:
              severity: info

          - alert: highCpuUsage
            expr: 100 - (avg by (host) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
            for: 10m
            labels:
              severity: warning

          - alert: highMemoryUsage
            expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
            for: 5m
            labels:
              severity: warning

          - alert: diskSpaceLow
            expr: (node_filesystem_avail_bytes{fstype=~"ext4|btrfs|xfs"} / node_filesystem_size_bytes{fstype=~"ext4|btrfs|xfs"}) * 100 < 10
            for: 5m
            labels:
              severity: warning

          - alert: diskSpaceCritical
            expr: (node_filesystem_avail_bytes{fstype=~"ext4|btrfs|xfs"} / node_filesystem_size_bytes{fstype=~"ext4|btrfs|xfs"}) * 100 < 5
            for: 2m
            labels:
              severity: critical

      - name: backup_health_alerts
        interval: 30s
        rules:

          - alert: backupNotRunRecently
            expr: time() - node_systemd_unit_start_time_seconds{name=~"borgbackup-job-.*", host=~"aspen|juniper"} > 90000
            for: 30m
            labels:
              severity: critical
            annotations:
              summary: "Backup has not run on {{ $labels.host }} in over 25 hours"

          - alert: backupServiceFailed
            expr: node_systemd_unit_state{name=~"borgbackup-job-.*|cloudBackup.service", state="failed", host=~"aspen|juniper"} == 1
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "Backup service {{ $labels.name }} failed on {{ $labels.host }}"

          - alert: cloudBackupStale
            expr: time() - node_systemd_unit_start_time_seconds{name="cloudBackup.service", host=~"aspen|juniper"} > 90000
            for: 30m
            labels:
              severity: critical
            annotations:
              summary: "Cloud backup has not synced on {{ $labels.host }} in over 25 hours"

      - name: disk_health_alerts
        interval: 60s
        rules:

          - alert: smartStatusFailed
            expr: smartctl_device_smart_status == 0
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "SMART status FAILED on {{ $labels.device }} ({{ $labels.host }})"

          - alert: diskReallocatedSectors
            expr: smartctl_device_attribute{attribute_name="Reallocated_Sector_Ct", attribute_value_type="raw"} > 0
            for: 1h
            labels:
              severity: warning
            annotations:
              summary: "{{ $labels.device }} on {{ $labels.host }} has {{ $value }} reallocated sectors"

          - alert: diskPendingSectors
            expr: smartctl_device_attribute{attribute_name="Current_Pending_Sector", attribute_value_type="raw"} > 0
            for: 30m
            labels:
              severity: critical
            annotations:
              summary: "{{ $labels.device }} on {{ $labels.host }} has {{ $value }} pending sectors (potential failure)"

          - alert: diskUncorrectableSectors
            expr: smartctl_device_attribute{attribute_name="Offline_Uncorrectable", attribute_value_type="raw"} > 0
            for: 30m
            labels:
              severity: critical
            annotations:
              summary: "{{ $labels.device }} on {{ $labels.host }} has {{ $value }} uncorrectable sectors (DATA LOSS RISK)"

          - alert: diskTemperatureHigh
            expr: smartctl_device_temperature{temperature_type="current"} > 55
            for: 15m
            labels:
              severity: warning
            annotations:
              summary: "{{ $labels.device }} on {{ $labels.host }} temperature {{ $value }}°C (threshold: 55°C)"

          - alert: diskTemperatureCritical
            expr: smartctl_device_temperature{temperature_type="current"} > 65
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "{{ $labels.device }} on {{ $labels.host }} temperature {{ $value }}°C (CRITICAL - risk of thermal damage)"
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
    templates."weekly-disk-health-env".content = ''
      WEBHOOK_URL=${config.sops.placeholder.chrisNotificationsWebhookUrl}
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

  systemd.services.weekly-disk-health = {
    description = "Weekly Disk Health Report Generator";
    after = [ "network-online.target" "prometheus.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.python3}/bin/python3 ${weeklyDiskHealthScript}";
      EnvironmentFile = config.sops.templates."weekly-disk-health-env".path;
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

  systemd.timers.weekly-disk-health = {
    description = "Weekly Disk Health Report Timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun 08:00:00";
      Persistent = true;  # run on next boot if missed
      RandomizedDelaySec = "30m";  # randomize within 30 minutes to avoid load spikes
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
                # aspen services - domain1
                "https://nextcloud.${configVars.domain1}"
                "https://identity.${configVars.domain1}"
                # aspen services - domain2
                "https://actual.${configVars.domain2}"
                "https://bond-ledger.${configVars.domain2}"
                "https://calibre-web.${configVars.domain2}"
                "https://chris-workouts.${configVars.domain2}"
                "https://danielle-workouts.${configVars.domain2}"
                "https://frigate.${configVars.domain2}"
                "https://home-assistant.${configVars.domain2}"
                "https://jellyfin.${configVars.domain2}"
                "https://jellyseerr.${configVars.domain2}"
                "https://n8n.${configVars.domain2}"
                "https://photos.${configVars.domain2}"
                "https://pihole-aspen.${configVars.domain2}/admin/login"
                "https://prowlarr.${configVars.domain2}"
                "https://radarr.${configVars.domain2}"
                "https://recipesage.${configVars.domain2}"
                "https://sabnzbd.${configVars.domain2}"
                "https://search.${configVars.domain2}"
                "https://sonarr.${configVars.domain2}"
                "https://stirling-pdf.${configVars.domain2}"
                "https://traefik-aspen.${configVars.domain2}"
                "https://unifi.${configVars.domain2}"
                "https://weekly-recipes.${configVars.domain2}"
                "https://zwavejs.${configVars.domain2}"
                # juniper services - domain1
                "https://matrix.${configVars.domain1}"
                "https://vaultwarden.${configVars.domain1}"
                # juniper services - domain2
                "https://alertmanager.${configVars.domain2}"
                "https://grafana.${configVars.domain2}"
                "https://homepage.${configVars.domain2}"
                "https://pihole-juniper.${configVars.domain2}/admin/login"
                "https://prometheus.${configVars.domain2}"
                "https://traefik-juniper.${configVars.domain2}"
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
            routes = [
              {
                matchers = [ "alertname=~hostDown|hostUp" ];
                receiver = "matrix-webhook";
                repeat_interval = "876000h"; # ~100 years = effectively never
                group_wait = "30s";
                group_interval = "5m";
              }
              # Mute endpoint alerts during nightly backup window
              {
                matchers = [ "alertname=publicEndpointDown" ];
                receiver = "matrix-webhook";
                mute_time_intervals = [ "nightly-backup-window" ];
              }
            ];
          };
          mute_time_intervals = [
            {
              name = "nightly-backup-window";
              time_intervals = [
                # all hosts backup at 02:30 EST/EDT (06:30-07:30 UTC depending on DST)
                # services are stopped, local borg backup runs (few minutes), services restart
                # 90-minute window covers local backup downtime + DST variation
                {
                  times = [
                    {
                      start_time = "06:25";
                      end_time = "07:45";
                    }
                  ];
                  # applies to all days (omitting weekdays field means every day)
                }
              ];
            }
          ];
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
              source_matchers = [ "alertname=hostDown" ];
              target_matchers = [ "alertname=publicEndpointDown" ];
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