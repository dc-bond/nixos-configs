{
  pkgs,
  config,
  lib,
  configVars,
  utils,
  ...
}:

let
  hostData = configVars.hosts.${config.networking.hostName};

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
        extraFlags = [ "--collector.textfile.directory=/var/lib/prometheus/node-exporter-text-files" ];
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

  # create textfile collector directory for node_exporter at boot
  # needed for hosts with impermanence where /var is ephemeral
  systemd.tmpfiles.rules = [
    "d /var/lib/prometheus/node-exporter-text-files 0755 root root -"
  ];

  systemd.services = {
    # export btrfs scrub metrics after each scrub completes
    # dynamically generate service name based on configured mountpoint
    "btrfs-scrub-${utils.escapeSystemdPath scrubMountpoint}" = lib.mkIf config.services.btrfs.autoScrub.enable {
      serviceConfig = {
        Type = lib.mkForce "oneshot";
        ExecStartPost = "${btrfsScrubExporter}";
      };
    };

    # wait for tailscale interface to have IP assigned before starting monitoring services
    tailscale-ready = {
      description = "Wait for Tailscale interface to have IP assigned";
      after = [ "tailscaled.service" ];
      wants = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "wait-for-tailscale-ip" ''
          set -euo pipefail

          # wait up to 30 seconds for tailscale interface to have IP assigned
          for i in {1..30}; do
            if ${pkgs.iproute2}/bin/ip -4 addr show tailscale0 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "inet ${hostData.networking.tailscaleIp}"; then
              echo "Tailscale IP ${hostData.networking.tailscaleIp} is assigned"
              exit 0
            fi
            sleep 1
          done

          echo "Timeout waiting for Tailscale IP assignment"
          exit 1
        '';
      };
    };

    # ensure monitoring services wait for tailscale interface to have IP assigned before binding
    prometheus-node-exporter = {
      after = [ "tailscale-ready.service" ];
      wants = [ "tailscale-ready.service" ];
    };
    prometheus-smartctl-exporter = lib.mkIf (hostData.hardware.enableSmartMonitoring or false) {
      after = [ "tailscale-ready.service" ];
      wants = [ "tailscale-ready.service" ];
    };
    cadvisor = lib.mkIf (config.virtualisation.oci-containers.containers != {}) {
      after = [ "tailscale-ready.service" ];
      wants = [ "tailscale-ready.service" ];
    };
  };

}