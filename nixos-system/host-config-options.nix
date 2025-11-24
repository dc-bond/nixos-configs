{ 
  lib, 
  ... 
}: 

{

  options.hostSpecificConfigs = {

    bootLoader = lib.mkOption {
      type = lib.types.enum [ "systemd-boot" "grub" ];
      description = "boot loader type for this host";
    };

    primaryIp = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "primary ipv4 address for this host";
    };

    storageDrive1 = lib.mkOption {
      type = lib.types.path;
      default = null;
      description = "path to storage drive 1";
    };

    isMonitoringServer = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "whether this host runs the central monitoring stack (prometheus, loki, grafana)";
    };
    
  };

}