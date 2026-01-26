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

    scrubInterval = lib.mkOption {
      type = lib.types.str;
      default = "Sun 03:00";
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
        description = "Number of 15-minute snapshots to keep (default: 4 = 1 hour)";
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

    enableEmailAlerts = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable email alerts for ZFS events (pool degradation, scrub results, etc.)";
    };

    alertEmail = lib.mkOption {
      type = lib.types.str;
      default = configVars.users.chris.email or "";
      description = "Email address for ZFS event notifications";
    };
  };

  config = lib.mkIf cfg.enable {
    # ZFS kernel support
    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs.forceImportRoot = false;

    # Required: Unique host ID for ZFS
    # Generate with: head -c 8 /etc/machine-id
    networking.hostId = lib.mkDefault (
      builtins.substring 0 8 (
        builtins.readFile /etc/machine-id or "00000000"
      )
    );

    # ZFS automatic scrubbing (integrity verification)
    services.zfs.autoScrub = {
      enable = true;
      interval = cfg.scrubInterval;
    };

    # ZFS automatic snapshots
    services.zfs.autoSnapshot = lib.mkIf cfg.enableSnapshots {
      enable = true;
      frequent = cfg.snapshotRetention.frequent;
      hourly = cfg.snapshotRetention.hourly;
      daily = cfg.snapshotRetention.daily;
      weekly = cfg.snapshotRetention.weekly;
      monthly = cfg.snapshotRetention.monthly;
    };

    # Disable TRIM for ZFS (not needed for HDDs, optional for SSDs)
    services.zfs.trim.enable = lib.mkDefault false;

    # ZFS Event Daemon (ZED) - Email notifications
    services.zfs.zed = lib.mkIf cfg.enableEmailAlerts {
      enableMail = true;
      settings = {
        ZED_EMAIL_ADDR = [ cfg.alertEmail ];
        ZED_EMAIL_PROG = "${pkgs.msmtp}/bin/msmtp";
        ZED_NOTIFY_VERBOSE = true;

        # Alert on these events
        ZED_NOTIFY_DATA = true;          # Data errors
        ZED_NOTIFY_IO_ERRORS = 10;       # Alert after 10 I/O errors
        ZED_NOTIFY_RESILVER = true;      # Resilver (rebuild) events
        ZED_SCRUB_AFTER_RESILVER = true; # Auto-scrub after resilver
      };
    };

    # Install ZFS utilities
    environment.systemPackages = with pkgs; [
      zfs
    ];

    # Helpful aliases for ZFS management
    environment.shellAliases = {
      zpool-status = "zpool status -v";
      zfs-snapshots = "zfs list -t snapshot";
      zfs-space = "zfs list -o space";
      zfs-health = "zpool list -Ho name,health,size,allocated,free,fragmentation";
    };
  };
}
