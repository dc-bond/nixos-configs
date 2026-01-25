{
  pkgs,
  config,
  lib,
  configVars,
  ...
}:

let
  hostData = configVars.hosts.${config.networking.hostName};

  btrfsScrubExporter = pkgs.writeShellScript "btrfs-scrub-exporter.sh" ''
    #!/usr/bin/env bash
    set -euo pipefail

    TEXTFILE_DIR="/var/lib/prometheus/node-exporter-text-files"
    METRICS_FILE="$TEXTFILE_DIR/btrfs_scrub.prom.$$"
    FINAL_FILE="$TEXTFILE_DIR/btrfs_scrub.prom"

    # Directory is created by systemd.tmpfiles.rules at boot
    # Find all btrfs filesystems
    for mountpoint in $(${pkgs.util-linux}/bin/findmnt -t btrfs -o TARGET -n | sort -u); do
      # Escape mountpoint for label (replace / with _)
      label=$(echo "$mountpoint" | sed 's/\//_/g' | sed 's/^_/root/')

      # Get scrub status
      scrub_status=$(${pkgs.btrfs-progs}/bin/btrfs scrub status "$mountpoint" 2>/dev/null || echo "")

      if echo "$scrub_status" | grep -q "scrub started"; then
        # Scrub is currently running
        echo "btrfs_scrub_status{mountpoint=\"$mountpoint\"} 2"
      elif echo "$scrub_status" | grep -q "finished after"; then
        # Scrub completed successfully
        echo "btrfs_scrub_status{mountpoint=\"$mountpoint\"} 1"

        # Extract error counts
        data_errors=$(echo "$scrub_status" | grep -oP 'data_extents_scrubbed.*?(\d+) errors' | grep -oP '\d+(?= errors)' | head -1 || echo "0")
        tree_errors=$(echo "$scrub_status" | grep -oP 'tree_extents_scrubbed.*?(\d+) errors' | grep -oP '\d+(?= errors)' | head -1 || echo "0")

        echo "btrfs_scrub_uncorrectable_errors_total{mountpoint=\"$mountpoint\",type=\"data\"} $data_errors"
        echo "btrfs_scrub_uncorrectable_errors_total{mountpoint=\"$mountpoint\",type=\"tree\"} $tree_errors"

        # Extract duration (format: HH:MM:SS)
        duration=$(echo "$scrub_status" | grep -oP 'finished after \K[0-9:]+' | head -1 || echo "00:00:00")
        duration_seconds=$(echo "$duration" | ${pkgs.gawk}/bin/awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }')
        echo "btrfs_scrub_duration_seconds{mountpoint=\"$mountpoint\"} $duration_seconds"

        # Get timestamp from systemd unit (best effort)
        unit_name="btrfs-scrub@$(${pkgs.systemd}/bin/systemd-escape --path "$mountpoint").service"
        last_run=$(${pkgs.systemd}/bin/systemctl show "$unit_name" --property=ExecMainExitTimestamp --value 2>/dev/null || echo "")
        if [ -n "$last_run" ] && [ "$last_run" != "n/a" ]; then
          timestamp=$(date -d "$last_run" +%s 2>/dev/null || echo "0")
          echo "btrfs_scrub_last_completion_timestamp{mountpoint=\"$mountpoint\"} $timestamp"
        fi

        # Get bytes scrubbed
        data_bytes=$(echo "$scrub_status" | grep -oP 'data_bytes_scrubbed: \K\d+' | head -1 || echo "0")
        echo "btrfs_scrub_bytes_scrubbed{mountpoint=\"$mountpoint\"} $data_bytes"
      elif echo "$scrub_status" | grep -q "no stats"; then
        # Never run
        echo "btrfs_scrub_status{mountpoint=\"$mountpoint\"} 3"
      else
        # Failed or unknown
        echo "btrfs_scrub_status{mountpoint=\"$mountpoint\"} 0"
      fi
    done > "$METRICS_FILE"

    # Atomic move to prevent partial reads
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
    "btrfs-scrub@" = lib.mkIf config.services.btrfs.autoScrub.enable {
      serviceConfig = {
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