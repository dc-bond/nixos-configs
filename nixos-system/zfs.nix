{
  config,
  lib,
  pkgs,
  configVars,
  ...
}:

let
  cfg = config.services.zfsExtended;
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

  };

}