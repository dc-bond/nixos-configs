{
  config,
  lib,
  pkgs,
  configVars,
  ...
}:

let
  cfg = config.services.zfsExtended;

  # TODO: uncomment after aspen re-install with ZFS pool
  #zfsScrubExporter = pkgs.writeShellScript "zfs-scrub-exporter.sh" ''
  #  #!/usr/bin/env bash
  #  set -euo pipefail
  #
  #  TEXTFILE_DIR="/var/lib/prometheus/node-exporter-text-files"
  #  METRICS_FILE="$TEXTFILE_DIR/zfs_scrub.prom.$$"
  #  FINAL_FILE="$TEXTFILE_DIR/zfs_scrub.prom"
  #
  #  # iterate through all configured pools
  #  for pool in ${lib.concatStringsSep " " cfg.pools}; do
  #    # get scrub status for this pool
  #    scrub_status=$(${pkgs.zfs}/bin/zpool status "$pool" 2>/dev/null || echo "")
  #
  #    if grep -q "scrub in progress" <<< "$scrub_status"; then
  #      # scrub is currently running
  #      echo "zfs_scrub_status{pool=\"$pool\"} 2"
  #    elif grep -q "scrub repaired" <<< "$scrub_status" || grep -q "scrub completed" <<< "$scrub_status"; then
  #      # scrub completed successfully
  #      echo "zfs_scrub_status{pool=\"$pool\"} 1"
  #
  #      # extract error count - bytes repaired indicates errors
  #      repaired=$(grep -oP 'scrub repaired \K[\d.]+[KMGT]?' <<< "$scrub_status" || echo "0")
  #      if [ "$repaired" = "0" ] || [ "$repaired" = "0B" ]; then
  #        echo "zfs_scrub_errors_repaired_bytes{pool=\"$pool\"} 0"
  #      else
  #        # convert to bytes
  #        value=$(echo "$repaired" | sed 's/[KMGT]$//')
  #        case "$repaired" in
  #          *T) multiplier=1099511627776 ;;  # 1024^4
  #          *G) multiplier=1073741824 ;;     # 1024^3
  #          *M) multiplier=1048576 ;;        # 1024^2
  #          *K) multiplier=1024 ;;           # 1024^1
  #          *)  multiplier=1 ;;              # bytes
  #        esac
  #        repaired_bytes=$(${pkgs.gawk}/bin/awk -v val="$value" -v mult="$multiplier" 'BEGIN { printf "%.0f", val * mult }')
  #        echo "zfs_scrub_errors_repaired_bytes{pool=\"$pool\"} $repaired_bytes"
  #      fi
  #
  #      # extract duration if available
  #      duration_line=$(grep -A1 "scan:" <<< "$scrub_status" | tail -1 || echo "")
  #      if [[ "$duration_line" =~ ([0-9]+)h([0-9]+)m ]]; then
  #        hours="''${BASH_REMATCH[1]}"
  #        minutes="''${BASH_REMATCH[2]}"
  #        duration_seconds=$(( (hours * 3600) + (minutes * 60) ))
  #        echo "zfs_scrub_duration_seconds{pool=\"$pool\"} $duration_seconds"
  #      elif [[ "$duration_line" =~ ([0-9]+) days ]]; then
  #        days="''${BASH_REMATCH[1]}"
  #        # extract hours and minutes after days
  #        if [[ "$duration_line" =~ ([0-9]+):([0-9]+):([0-9]+) ]]; then
  #          hours="''${BASH_REMATCH[1]}"
  #          minutes="''${BASH_REMATCH[2]}"
  #          seconds="''${BASH_REMATCH[3]}"
  #          duration_seconds=$(( (days * 86400) + (hours * 3600) + (minutes * 60) + seconds ))
  #          echo "zfs_scrub_duration_seconds{pool=\"$pool\"} $duration_seconds"
  #        fi
  #      fi
  #
  #      # extract completion timestamp if available
  #      if [[ "$scrub_status" =~ "on "(.+) ]]; then
  #        timestamp_str="''${BASH_REMATCH[1]}"
  #        timestamp=$(date -d "$timestamp_str" +%s 2>/dev/null || echo "0")
  #        if [ "$timestamp" != "0" ]; then
  #          echo "zfs_scrub_last_completion_timestamp{pool=\"$pool\"} $timestamp"
  #        fi
  #      fi
  #
  #      # extract scanned bytes
  #      scanned=$(grep -oP 'scanned out of \K[\d.]+[KMGT]?' <<< "$scrub_status" || echo "0")
  #      if [ "$scanned" != "0" ]; then
  #        value=$(echo "$scanned" | sed 's/[KMGT]$//')
  #        case "$scanned" in
  #          *T) multiplier=1099511627776 ;;
  #          *G) multiplier=1073741824 ;;
  #          *M) multiplier=1048576 ;;
  #          *K) multiplier=1024 ;;
  #          *)  multiplier=1 ;;
  #        esac
  #        scanned_bytes=$(${pkgs.gawk}/bin/awk -v val="$value" -v mult="$multiplier" 'BEGIN { printf "%.0f", val * mult }')
  #        echo "zfs_scrub_total_bytes{pool=\"$pool\"} $scanned_bytes"
  #      fi
  #
  #    elif grep -q "none requested" <<< "$scrub_status"; then
  #      # never run
  #      echo "zfs_scrub_status{pool=\"$pool\"} 3"
  #    else
  #      # failed or unknown
  #      echo "zfs_scrub_status{pool=\"$pool\"} 0"
  #    fi
  #  done > "$METRICS_FILE"
  #
  #  # atomic move to prevent partial reads
  #  mv "$METRICS_FILE" "$FINAL_FILE"
  #'';

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

      # Optional: Limit ZFS ARC (adaptive replacement cache) memory usage
      # By default, ZFS uses ~50% of system RAM for caching
      # Uncomment and adjust if experiencing memory pressure with other services
      # kernelParams = [
      #   "zfs.zfs_arc_max=8589934592"  # Limit to 8GB (in bytes)
      # ];
    };

    services.zfs = {
      # automatic scrubbing (integrity verification)
      autoScrub = {
        enable = true;
        interval = cfg.scrubInterval;
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

    # TODO: uncomment after aspen re-install with ZFS pool
    # hook into ZFS scrub services to export metrics after completion
    #systemd.services = lib.mkMerge (lib.forEach cfg.pools (pool: {
    #  "zfs-scrub-${pool}" = {
    #    serviceConfig.ExecStartPost = lib.mkAfter "${zfsScrubExporter}";
    #  };
    #}));

  };

}