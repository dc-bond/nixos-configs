{
  pkgs,
  config,
  lib,
  configVars,
  nixServiceRecoveryScript,
  utils,
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

  # get the first configured scrub mountpoint (most hosts only have one)
  scrubMountpoint = if config.services.btrfs.autoScrub.enable
    then builtins.head config.services.btrfs.autoScrub.fileSystems
    else "/";

  btrfsScrubExporter = pkgs.writeShellScript "btrfs-scrub-exporter.sh" ''
    #!/usr/bin/env bash
    set -euo pipefail

    TEXTFILE_DIR="/var/lib/prometheus/node-exporter-text-files"
    METRICS_FILE="$TEXTFILE_DIR/btrfs_scrub.prom.$$"
    FINAL_FILE="$TEXTFILE_DIR/btrfs_scrub.prom"

    # check scrub status for configured filesystem
    mountpoint="${scrubMountpoint}"
    scrub_status=$(${pkgs.btrfs-progs}/bin/btrfs scrub status "$mountpoint" 2>/dev/null || echo "")

    if grep -q "Status:.*running" <<< "$scrub_status"; then
      # scrub is currently running
      echo "btrfs_scrub_status{mountpoint=\"$mountpoint\"} 2"
    elif grep -q "Status:.*finished" <<< "$scrub_status"; then
      # scrub completed successfully
      echo "btrfs_scrub_status{mountpoint=\"$mountpoint\"} 1"

      # extract error count - use default 0 if not found
      errors=$(grep -oP 'Error summary:\s+\K\d+' <<< "$scrub_status" || echo "0")
      echo "btrfs_scrub_errors_total{mountpoint=\"$mountpoint\"} $errors"

      # extract duration and convert to seconds
      duration=$(grep -oP 'Duration:\s+\K[0-9:]+' <<< "$scrub_status" || echo "0:00:00")
      # handle formats: HH:MM:SS, H:MM:SS, or MM:SS
      IFS=: read -r h m s <<< "$duration"
      # if only 2 fields (MM:SS), treat first as minutes
      if [ -z "$s" ]; then s=$m; m=$h; h=0; fi
      duration_seconds=$(( (h * 3600) + (m * 60) + s ))
      echo "btrfs_scrub_duration_seconds{mountpoint=\"$mountpoint\"} $duration_seconds"

      # get timestamp from systemd service
      service_name="btrfs-scrub-$(${pkgs.systemd}/bin/systemd-escape --path "$mountpoint").service"
      last_run=$(${pkgs.systemd}/bin/systemctl show "$service_name" --property=ExecMainExitTimestamp --value 2>/dev/null || echo "")
      if [ -n "$last_run" ] && [ "$last_run" != "n/a" ]; then
        timestamp=$(date -d "$last_run" +%s 2>/dev/null || echo "0")
        if [ "$timestamp" != "0" ]; then
          echo "btrfs_scrub_last_completion_timestamp{mountpoint=\"$mountpoint\"} $timestamp"
        fi
      fi

      # extract total bytes with unit handling
      size_line=$(grep "Total to scrub:" <<< "$scrub_status" || echo "")
      if [ -n "$size_line" ]; then
        size_value=$(grep -oP 'Total to scrub:\s+\K[\d.]+' <<< "$size_line")
        case "$size_line" in
          *TiB*) multiplier=1099511627776 ;;  # 1024^4
          *GiB*) multiplier=1073741824 ;;     # 1024^3
          *MiB*) multiplier=1048576 ;;        # 1024^2
          *KiB*) multiplier=1024 ;;           # 1024^1
          *)     multiplier=1 ;;              # assume bytes
        esac
        total_bytes=$(${pkgs.gawk}/bin/awk -v val="$size_value" -v mult="$multiplier" 'BEGIN { printf "%.0f", val * mult }')
        echo "btrfs_scrub_total_bytes{mountpoint=\"$mountpoint\"} $total_bytes"
      fi
    elif grep -q "no stats" <<< "$scrub_status"; then
      # never run
      echo "btrfs_scrub_status{mountpoint=\"$mountpoint\"} 3"
    else
      # failed or unknown
      echo "btrfs_scrub_status{mountpoint=\"$mountpoint\"} 0"
    fi > "$METRICS_FILE"

    # atomic move to prevent partial reads
    mv "$METRICS_FILE" "$FINAL_FILE"
  '';

  smartHealthScript = pkgs.writeText "smart-health.py" ''
    #!/usr/bin/env python3
    import json
    import urllib.request
    import urllib.error
    import os
    import re
    from datetime import datetime

    PROMETHEUS_URL = "http://127.0.0.1:9090"
    WEBHOOK_URL = os.environ.get("WEBHOOK_URL", "")

    def query_prometheus(query):
        """query prometheus and return results"""
        url = f"{PROMETHEUS_URL}/api/v1/query?query={urllib.parse.quote(query)}"
        try:
            with urllib.request.urlopen(url, timeout=10) as response:
                data = json.loads(response.read().decode("utf-8"))
                if data.get("status") == "success":
                    return data.get("data", {}).get("result", [])
        except Exception as e:
            print(f"error querying prometheus: {e}")
        return []

    def format_hours(hours):
        """convert hours to years, months, days (approximate)"""
        years = hours // 8760  # 365 * 24
        remaining = hours % 8760
        months = remaining // 730  # approximate: 30.4 days/month * 24
        days = (remaining % 730) // 24

        parts = []
        if years > 0:
            parts.append(f"{years}y")
        if months > 0:
            parts.append(f"{months}m")
        if days > 0:
            parts.append(f"{days}d")
        return " ".join(parts) if parts else "0d"

    def get_disk_data():
        """get all disk data in one batch to avoid duplicate queries"""
        disks = {}

        # get disk inventory
        results = query_prometheus('smartctl_device')
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

        # batch query all SMART statuses
        smart_results = query_prometheus('smartctl_device_smart_status')
        for result in smart_results:
            labels = result["metric"]
            key = f"{labels.get('host')}:{labels.get('device')}"
            if key in disks:
                value = int(result["value"][1])
                disks[key]["smart_status"] = "PASSED" if value == 1 else "FAILED"

        # batch query all temperatures
        temp_results = query_prometheus('smartctl_device_temperature{temperature_type="current"}')
        for result in temp_results:
            labels = result["metric"]
            key = f"{labels.get('host')}:{labels.get('device')}"
            if key in disks:
                disks[key]["temperature"] = int(result["value"][1])

        # batch query all power-on hours
        hours_results = query_prometheus('smartctl_device_attribute{attribute_name="Power_On_Hours",attribute_value_type="raw"}')
        for result in hours_results:
            labels = result["metric"]
            key = f"{labels.get('host')}:{labels.get('device')}"
            if key in disks:
                disks[key]["power_on_hours"] = int(float(result["value"][1]))

        # batch query reallocated sectors
        realloc_results = query_prometheus('smartctl_device_attribute{attribute_name="Reallocated_Sector_Ct",attribute_value_type="raw"}')
        for result in realloc_results:
            labels = result["metric"]
            key = f"{labels.get('host')}:{labels.get('device')}"
            if key in disks:
                disks[key]["reallocated_sectors"] = int(float(result["value"][1]))

        # batch query pending sectors
        pending_results = query_prometheus('smartctl_device_attribute{attribute_name="Current_Pending_Sector",attribute_value_type="raw"}')
        for result in pending_results:
            labels = result["metric"]
            key = f"{labels.get('host')}:{labels.get('device')}"
            if key in disks:
                disks[key]["pending_sectors"] = int(float(result["value"][1]))

        # batch query uncorrectable sectors
        uncorr_results = query_prometheus('smartctl_device_attribute{attribute_name="Offline_Uncorrectable",attribute_value_type="raw"}')
        for result in uncorr_results:
            labels = result["metric"]
            key = f"{labels.get('host')}:{labels.get('device')}"
            if key in disks:
                disks[key]["uncorrectable_sectors"] = int(float(result["value"][1]))

        return disks

    def generate_report():
        """generate comprehensive smart disk health report"""
        # batch query all data once
        disks = get_disk_data()

        if not disks:
            return "⚠️ no disks found in monitoring system"

        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        # header
        report = f"📊 **Weekly SMART Disk Health Report**\\n\\n"
        report += f"**Generated**: {timestamp}\\n"
        report += f"**Total Disks**: {len(disks)}\\n\\n"

        # overall health summary
        failed_disks = []
        warning_disks = []

        for key, disk in disks.items():
            status = disk.get("smart_status", "UNKNOWN")
            if status == "FAILED":
                failed_disks.append(key)

            # check for warning conditions
            reallocated = disk.get("reallocated_sectors", 0)
            pending = disk.get("pending_sectors", 0)
            temp = disk.get("temperature")

            if reallocated > 0 or pending > 0 or (temp and temp > 50):
                warning_disks.append(key)

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

        # detailed per-disk report
        for key, disk in sorted(disks.items()):
            report += f"**{disk['host']} - {disk['device']}**\\n"
            report += f"Model: {disk['model'][:40]}\\n"

            # smart status
            status = disk.get("smart_status", "UNKNOWN")
            status_emoji = "✅" if status == "PASSED" else "🔴"
            report += f"Status: {status_emoji} {status}\\n"

            # temperature
            temp = disk.get("temperature")
            if temp is not None:
                temp_emoji = "🌡️" if temp <= 50 else "🔥"
                report += f"Temp: {temp_emoji} {temp}°C\\n"

            # power-on hours
            hours = disk.get("power_on_hours")
            if hours is not None:
                runtime = format_hours(hours)
                report += f"Runtime: {runtime} ({hours:,} hours)\\n"

            # critical attributes
            reallocated = disk.get("reallocated_sectors", 0)
            pending = disk.get("pending_sectors", 0)
            uncorrectable = disk.get("uncorrectable_sectors", 0)

            if reallocated > 0:
                report += f"⚠️ Reallocated Sectors: {reallocated}\\n"
            if pending > 0:
                report += f"🔴 Pending Sectors: {pending}\\n"
            if uncorrectable > 0:
                report += f"🔴 Uncorrectable Sectors: {uncorrectable}\\n"

            report += "\\n"

        return report

    def send_webhook(message):
        """send report to matrix via webhook"""
        if not WEBHOOK_URL:
            print("ERROR: WEBHOOK_URL not set")
            return False

        # convert markdown to html for matrix
        html_message = message.replace("\\n", "<br/>")
        # replace **text** with <b>text</b> using regex
        html_message = re.sub(r'\*\*([^*]+)\*\*', r'<b>\1</b>', html_message)

        payload = json.dumps({
            "text": re.sub(r'\*\*([^*]+)\*\*', r'\1', message),  # plain text fallback (strip markdown)
            "html": html_message,
            "format": "org.matrix.custom.html"
        }).encode("utf-8")
        req = urllib.request.Request(
            WEBHOOK_URL,
            data=payload,
            headers={"Content-Type": "application/json"}
        )

        try:
            with urllib.request.urlopen(req, timeout=10) as response:
                # accept any 2xx status code as success
                return 200 <= response.status < 300
        except Exception as e:
            print(f"error sending webhook: {e}")
            return False

    if __name__ == "__main__":
        report = generate_report()
        print(report)

        if send_webhook(report):
            print("\\nReport sent successfully")
        else:
            print("\\nFailed to send report")
  '';

  btrfsHealthScript = pkgs.writeText "btrfs-health.py" ''
    #!/usr/bin/env python3
    import json
    import urllib.request
    import urllib.error
    import os
    import re
    from datetime import datetime

    PROMETHEUS_URL = "http://127.0.0.1:9090"
    WEBHOOK_URL = os.environ.get("WEBHOOK_URL", "")

    # status code constants
    SCRUB_FAILED = 0
    SCRUB_SUCCESS = 1
    SCRUB_RUNNING = 2
    SCRUB_NEVER_RUN = 3

    STATUS_MAP = {
        SCRUB_FAILED: "🔴 Failed",
        SCRUB_SUCCESS: "✅ Success",
        SCRUB_RUNNING: "🔄 Running",
        SCRUB_NEVER_RUN: "⚠️ Never Run"
    }

    def query_prometheus(query):
        """query prometheus and return results"""
        url = f"{PROMETHEUS_URL}/api/v1/query?query={urllib.parse.quote(query)}"
        try:
            with urllib.request.urlopen(url, timeout=10) as response:
                data = json.loads(response.read().decode("utf-8"))
                if data.get("status") == "success":
                    return data.get("data", {}).get("result", [])
        except Exception as e:
            print(f"error querying prometheus: {e}")
        return []

    def get_btrfs_data():
        """get all btrfs scrub data in one batch"""
        scrubs = {}

        # batch query all scrub statuses
        results = query_prometheus('btrfs_scrub_status')
        for result in results:
            labels = result["metric"]
            host = labels.get("host", "unknown")
            mountpoint = labels.get("mountpoint", "unknown")
            key = f"{host}:{mountpoint}"
            scrubs[key] = {
                "host": host,
                "mountpoint": mountpoint,
                "status_code": int(result["value"][1]),
            }

        # batch query all error counts
        error_results = query_prometheus('btrfs_scrub_errors_total')
        for result in error_results:
            labels = result["metric"]
            key = f"{labels.get('host')}:{labels.get('mountpoint')}"
            if key in scrubs:
                scrubs[key]["errors"] = int(result["value"][1])

        # batch query all timestamps
        timestamp_results = query_prometheus('btrfs_scrub_last_completion_timestamp')
        for result in timestamp_results:
            labels = result["metric"]
            key = f"{labels.get('host')}:{labels.get('mountpoint')}"
            if key in scrubs:
                scrubs[key]["last_run"] = int(result["value"][1])

        # batch query all durations
        duration_results = query_prometheus('btrfs_scrub_duration_seconds')
        for result in duration_results:
            labels = result["metric"]
            key = f"{labels.get('host')}:{labels.get('mountpoint')}"
            if key in scrubs:
                scrubs[key]["duration"] = int(result["value"][1])

        # batch query all total bytes
        bytes_results = query_prometheus('btrfs_scrub_total_bytes')
        for result in bytes_results:
            labels = result["metric"]
            key = f"{labels.get('host')}:{labels.get('mountpoint')}"
            if key in scrubs:
                scrubs[key]["total_bytes"] = int(result["value"][1])

        return scrubs

    def format_duration(seconds):
        """convert seconds to human readable duration"""
        hours = seconds // 3600
        minutes = (seconds % 3600) // 60
        secs = seconds % 60
        return f"{hours}h {minutes}m {secs}s"

    def format_bytes(total_bytes):
        """convert bytes to human readable size"""
        if total_bytes == 0:
            return "unknown"
        gb = total_bytes / 1073741824  # 1024^3
        return f"{gb:.2f} GiB"

    def generate_report():
        """generate comprehensive btrfs scrub health report"""
        scrubs = get_btrfs_data()

        if not scrubs:
            return "⚠️ no btrfs filesystems found in monitoring system"

        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        # header
        report = f"🔍 **Weekly BTRFS Scrub Report**\\n\\n"
        report += f"**Generated**: {timestamp}\\n"
        report += f"**Total Filesystems**: {len(scrubs)}\\n\\n"

        # overall health summary
        scrub_failed = []
        scrub_errors = []
        scrub_ok = []

        for key, scrub in scrubs.items():
            status_code = scrub["status_code"]
            errors = scrub.get("errors", 0)

            if errors > 0:
                scrub_errors.append(f"{key} ({errors} errors)")
            elif status_code == SCRUB_FAILED:
                scrub_failed.append(key)
            elif status_code == SCRUB_SUCCESS:
                scrub_ok.append(key)

        # summary
        if scrub_errors:
            report += f"🔴 **CRITICAL**: {len(scrub_errors)} filesystem(s) with data corruption\\n"
            for item in scrub_errors:
                report += f"   • {item}\\n"
            report += "\\n"

        if scrub_failed:
            report += f"⚠️ **WARNING**: {len(scrub_failed)} filesystem(s) with failed scrubs\\n"
            for item in scrub_failed:
                report += f"   • {item}\\n"
            report += "\\n"

        # only show summary if there are errors or failures
        # omit the "all successful" line when everything is OK

        report += "---\\n\\n"

        # detailed per-filesystem report
        for key, scrub in sorted(scrubs.items()):
            host = scrub["host"]
            mountpoint = scrub["mountpoint"]
            status_code = scrub["status_code"]

            report += f"**{host}: {mountpoint}**\\n"

            # status
            status = STATUS_MAP.get(status_code, "❓ Unknown")
            report += f"Status: {status}\\n"

            # duration
            duration = scrub.get("duration", 0)
            if duration > 0:
                report += f"Duration: {format_duration(duration)}\\n"

            # size scrubbed
            total_bytes = scrub.get("total_bytes", 0)
            if total_bytes > 0:
                report += f"Size Scrubbed: {format_bytes(total_bytes)}\\n"

            # error count
            errors = scrub.get("errors", 0)
            if errors > 0:
                report += f"🔴 Errors: {errors}\\n"
            else:
                report += f"Errors: 0 (all data verified)\\n"

            # last run timestamp
            last_run_timestamp = scrub.get("last_run")
            if last_run_timestamp:
                last_run = datetime.fromtimestamp(last_run_timestamp).strftime("%Y-%m-%d %H:%M:%S")
                days_ago = (datetime.now().timestamp() - last_run_timestamp) / 86400
                report += f"Last Run: {last_run} ({days_ago:.1f} days ago)\\n"

            report += "\\n"

        return report

    def send_webhook(message):
        """send report to matrix via webhook"""
        if not WEBHOOK_URL:
            print("ERROR: WEBHOOK_URL not set")
            return False

        # convert markdown to html for matrix
        html_message = message.replace("\\n", "<br/>")
        # replace **text** with <b>text</b> using regex
        html_message = re.sub(r'\*\*([^*]+)\*\*', r'<b>\1</b>', html_message)

        payload = json.dumps({
            "text": re.sub(r'\*\*([^*]+)\*\*', r'\1', message),  # plain text fallback (strip markdown)
            "html": html_message,
            "format": "org.matrix.custom.html"
        }).encode("utf-8")
        req = urllib.request.Request(
            WEBHOOK_URL,
            data=payload,
            headers={"Content-Type": "application/json"}
        )

        try:
            with urllib.request.urlopen(req, timeout=10) as response:
                # accept any 2xx status code as success
                return 200 <= response.status < 300
        except Exception as e:
            print(f"error sending webhook: {e}")
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
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "{{ $labels.instance }} is down (probe failed)"


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

      - name: btrfs_scrub_alerts
        interval: 60s
        rules:

          - alert: btrfsDataCorruption
            expr: btrfs_scrub_errors_total > 0
            for: 1m
            labels:
              severity: critical
            annotations:
              summary: "BTRFS DATA CORRUPTION detected on {{ $labels.mountpoint }} ({{ $labels.host }}) - {{ $value }} {{ $labels.type }} errors found"

          - alert: btrfsScrubNotRunning
            expr: time() - btrfs_scrub_last_completion_timestamp > 604800
            for: 30m
            labels:
              severity: warning
            annotations:
              summary: "BTRFS scrub has not completed on {{ $labels.mountpoint }} ({{ $labels.host }}) in over 7 days"

          - alert: btrfsScrubFailed
            expr: btrfs_scrub_status == 0
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "BTRFS scrub failed on {{ $labels.mountpoint }} ({{ $labels.host }})"

          - alert: btrfsScrubNeverRun
            expr: btrfs_scrub_status == 3
            for: 1h
            labels:
              severity: warning
            annotations:
              summary: "BTRFS scrub has never run on {{ $labels.mountpoint }} ({{ $labels.host }})"

          - alert: btrfsScrubMetricsStale
            expr: time() - btrfs_scrub_last_completion_timestamp > 691200
            for: 1h
            labels:
              severity: warning
            annotations:
              summary: "BTRFS scrub metrics on {{ $labels.mountpoint }} ({{ $labels.host }}) haven't updated in over 8 days (monitoring may be broken)"
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
    templates."smart-health-env".content = ''
      WEBHOOK_URL=${config.sops.placeholder.chrisNotificationsWebhookUrl}
    '';
    templates."btrfs-health-env".content = ''
      WEBHOOK_URL=${config.sops.placeholder.chrisNotificationsWebhookUrl}
    '';
  };

  # create textfile collector directory for node_exporter at boot
  # needed for hosts with impermanence where /var is ephemeral
  systemd.tmpfiles.rules = [
    "d /var/lib/prometheus/node-exporter-text-files 0755 root root -"
  ];

  systemd = {
    services = {
      # export btrfs scrub metrics after each scrub completes
      # dynamically generate service name based on configured mountpoint
      "btrfs-scrub-${utils.escapeSystemdPath scrubMountpoint}" = lib.mkIf config.services.btrfs.autoScrub.enable {
        serviceConfig = {
          Type = lib.mkForce "oneshot";
          ExecStartPost = "${btrfsScrubExporter}";
        };
      };
      alertmanager-to-hookshot = {
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
          ProtectKernelTunnels = true;
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
      smart-health = {
        description = "Weekly SMART Disk Health Report Generator";
        after = [ "network-online.target" "prometheus.service" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.python3}/bin/python3 ${smartHealthScript}";
          EnvironmentFile = config.sops.templates."smart-health-env".path;
          DynamicUser = true;
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectKernelTunnels = true;
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
      btrfs-health = {
        description = "Weekly BTRFS Scrub Health Report Generator";
        after = [ "network-online.target" "prometheus.service" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.python3}/bin/python3 ${btrfsHealthScript}";
          EnvironmentFile = config.sops.templates."btrfs-health-env".path;
          DynamicUser = true;
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectKernelTunnels = true;
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
    };
    timers = {
      smart-health = {
        description = "Weekly SMART Disk Health Report Timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "Sun 05:00:00";  # sunday 05:00 (after 04:00 btrfs scrub)
          Persistent = true;  # run on next boot if missed
          RandomizedDelaySec = "5m";  # randomize within 5 minutes to avoid load spikes
        };
      };
      btrfs-health = {
        description = "Weekly BTRFS Scrub Health Report Timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "Sun 04:30:00";  # sunday 04:30 (30 min after 04:00 scrub starts)
          Persistent = true;  # run on next boot if missed
          RandomizedDelaySec = "5m";  # randomize within 5 minutes to avoid load spikes
        };
      };
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
          extraFlags = [ "--collector.textfile.directory=/var/lib/prometheus/node-exporter-text-files" ];
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