{
  config,
  lib,
  pkgs,
  configVars,
  ...
}:

let
  cfg = config.services.zfsExtended;

  zfsScrubExporter = pkgs.writeShellScript "zfs-scrub-exporter.sh" ''
    #!/usr/bin/env bash
    set -euo pipefail

    TEXTFILE_DIR="/var/lib/prometheus/node-exporter-text-files"
    METRICS_FILE="$TEXTFILE_DIR/zfs_scrub.prom.$$"
    FINAL_FILE="$TEXTFILE_DIR/zfs_scrub.prom"

    to_bytes() {
      case "$2" in
        P) multiplier=1125899906842624 ;;
        T) multiplier=1099511627776 ;;
        G) multiplier=1073741824 ;;
        M) multiplier=1048576 ;;
        K) multiplier=1024 ;;
        *) multiplier=1 ;;
      esac
      ${pkgs.gawk}/bin/awk -v val="$1" -v mult="$multiplier" 'BEGIN { printf "%.0f", val * mult }'
    }

    # e.g. "scan: scrub repaired 0B in 03:43:57 with 0 errors on Mon Sep 28 09:23:08 2026";
    # runs of a day or more read "in 1 days 02:03:04"
    completed_re='scrub repaired ([0-9.]+)([KMGTP]?)B? in (([0-9]+) days? )?([0-9]+):([0-9]+):([0-9]+) with ([0-9]+) errors on (.+)$'

    for pool in ${lib.concatStringsSep " " cfg.pools}; do
      # only the scan line: the status/action text above it also contains " on "
      scan_line=$(${pkgs.zfs}/bin/zpool status "$pool" 2>/dev/null | grep -E '^[[:space:]]*scan:' || true)

      if [[ "$scan_line" == *"scrub in progress"* ]]; then
        echo "zfs_scrub_status{pool=\"$pool\"} 2"
      elif [[ "$scan_line" =~ $completed_re ]]; then
        repaired_value="''${BASH_REMATCH[1]}"
        repaired_unit="''${BASH_REMATCH[2]}"
        days="''${BASH_REMATCH[4]:-0}"
        hours="''${BASH_REMATCH[5]}"
        minutes="''${BASH_REMATCH[6]}"
        seconds="''${BASH_REMATCH[7]}"
        finished="''${BASH_REMATCH[9]}"

        echo "zfs_scrub_status{pool=\"$pool\"} 1"
        echo "zfs_scrub_errors_repaired_bytes{pool=\"$pool\"} $(to_bytes "$repaired_value" "$repaired_unit")"
        echo "zfs_scrub_duration_seconds{pool=\"$pool\"} $(( 10#$days * 86400 + 10#$hours * 3600 + 10#$minutes * 60 + 10#$seconds ))"

        timestamp=$(date -d "$finished" +%s 2>/dev/null || echo "0")
        if [ "$timestamp" != "0" ]; then
          echo "zfs_scrub_last_completion_timestamp{pool=\"$pool\"} $timestamp"
        fi

        # a completed scan line carries no size; a scrub reads every allocated byte
        allocated=$(${pkgs.zfs}/bin/zpool list -Hp -o allocated "$pool" 2>/dev/null || echo "0")
        echo "zfs_scrub_total_bytes{pool=\"$pool\"} $allocated"
      elif [[ "$scan_line" == *"none requested"* || -z "$scan_line" ]]; then
        # never run
        echo "zfs_scrub_status{pool=\"$pool\"} 3"
      else
        # canceled, or a format this parser does not know
        echo "zfs_scrub_status{pool=\"$pool\"} 0"
      fi
    done > "$METRICS_FILE"

    # atomic move to prevent partial reads
    mv "$METRICS_FILE" "$FINAL_FILE"
  '';

in

{

  options.services.zfsExtended = {

    enable = lib.mkEnableOption "ZFS extended configuration with snapshots, scrubbing, and monitoring";

    pools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of ZFS pools to auto-import at boot";
      example = [ "storage" "tank" ];
    };

    scrubInterval = lib.mkOption {
      type = lib.types.str;
      default = "Mon 03:00";
      description = "When to run ZFS scrub (integrity verification)";
      example = "weekly";
    };

    enableSnapshots = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable automatic ZFS snapshots";
    };

    datasetQuotas = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Quotas to enforce on ZFS datasets";
      example = { "storage/root/media/security-cameras" = "2T"; };
    };

    snapshotRetention = {
      frequent = lib.mkOption {
        type = lib.types.int;
        default = 4;
        description = "Number of 15-minute snapshots to keep";
      };

      hourly = lib.mkOption {
        type = lib.types.int;
        default = 24;
        description = "Number of hourly snapshots to keep";
      };

      daily = lib.mkOption {
        type = lib.types.int;
        default = 7;
        description = "Number of daily snapshots to keep";
      };

      weekly = lib.mkOption {
        type = lib.types.int;
        default = 4;
        description = "Number of weekly snapshots to keep";
      };

      monthly = lib.mkOption {
        type = lib.types.int;
        default = 12;
        description = "Number of monthly snapshots to keep";
      };
    };

  };

  config = lib.mkIf cfg.enable {

    environment = {
      systemPackages = with pkgs; [ zfs ]; # install zfs utilities
      shellAliases = {
        zpool-status = "zpool status -v";
        zfs-snapshots = "zfs list -t snapshot";
        zfs-space = "zfs list -o space";
        zfs-health = "zpool list -Ho name,health,size,allocated,free,fragmentation";
      };
    };

    boot = {
      supportedFilesystems = [ "zfs" ];
      zfs = {
        forceImportRoot = false;
        extraPools = cfg.pools; # auto-import specified pools at boot
      };
      kernelParams = [ "zfs.zfs_arc_max=8589934592" ]; # limit zfs adaptive replacement cache memory usage to 8GB (in bytes) to avoid memory pressure with other services
    };

    services.zfs = {
      # automatic scrubbing (integrity verification)
      autoScrub = {
        enable = true;
        interval = cfg.scrubInterval;
        randomizedDelaySec = "0"; # start on schedule; juniper's weekly zfs-health report runs a fixed time after it
      };
      # automatic snapshots
      autoSnapshot = lib.mkIf cfg.enableSnapshots {
        enable = true;
        frequent = cfg.snapshotRetention.frequent;
        hourly = cfg.snapshotRetention.hourly;
        daily = cfg.snapshotRetention.daily;
        weekly = cfg.snapshotRetention.weekly;
        monthly = cfg.snapshotRetention.monthly;
      };
      trim.enable = lib.mkDefault false; # disable for HDDs, can be enabled for SSD pools
    };

    # zfs-scrub is Type=simple around `zpool scrub -w`, so ExecStartPost would
    # fire at scrub start and export the previous run; stop-post fires on completion
    systemd.services.zfs-scrub.serviceConfig.ExecStopPost = lib.mkAfter "${zfsScrubExporter}";

    # quotas live in pool metadata, not in the nix store, so reassert them at
    # boot rather than assuming whatever the pool was last set to by hand
    systemd.services.zfs-dataset-quotas = lib.mkIf (cfg.datasetQuotas != {}) {
      description = "Apply declared ZFS dataset quotas";
      after = [ "zfs-import.target" ];
      requires = [ "zfs-import.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = lib.concatStringsSep "\n" (lib.mapAttrsToList
        (dataset: quota: "${pkgs.zfs}/bin/zfs set quota=${quota} ${dataset}")
        cfg.datasetQuotas);
    };

  };

}