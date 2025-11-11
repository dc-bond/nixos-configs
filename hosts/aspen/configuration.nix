{ 
  inputs, 
  outputs, 
  lib, 
  configLib,
  config, 
  configVars,
  pkgs, 
  ... 
}: 

{

  options.hostSpecificConfigs = {
    storageDrive1 = lib.mkOption {
      type = lib.types.path;
      description = "path to storage drive 1";
    };
    primaryIp = lib.mkOption {
      type = lib.types.str;
      description = "primary ipv4 address for this host";
    };
    sshdPort = lib.mkOption {
      type = lib.types.int;
      description = "ssh daemon port for this host";
    };
    isMonitoringServer = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "whether this host runs the central monitoring stack (prometheus, loki, grafana)";
    };
  };

  config = {

    hostSpecificConfigs = {
      storageDrive1 = "/storage/WD-WCC7K4RU947F";
      primaryIp = configVars.aspenLanIp;
      sshdPort = 28766;
      isMonitoringServer = true;
    };

    fileSystems."${config.hostSpecificConfigs.storageDrive1}" = {
      device = "/dev/disk/by-uuid/2dbedc67-9a6b-477f-a3b4-75116994d1cb";
      fsType = "ext4"; 
      options = [ "defaults" ];
    };

    networking.hostName = "aspen";

    backups = {
      borgDir = "${config.hostSpecificConfigs.storageDrive1}/borgbackup"; # host-specific borg backup directory override on backups.nix
      startTime = "*-*-* 02:05:00"; # everyday at 2:05am
    };

    services.borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter [ "${config.hostSpecificConfigs.storageDrive1}/media/family-media" ]; # backup media directory outside of any individual service backup context

    environment.systemPackages = with pkgs; [
      wget # download tool
      usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
      rsync # sync tool
      btop # system monitor
    ];

    # original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
    system.stateVersion = "24.11";

  };

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "hosts/aspen/disk-config-btrfs.nix"
      "hosts/aspen/hardware-configuration.nix"
      "nixos-system/boot.nix"
      "nixos-system/networking.nix"
      "nixos-system/crowdsec.nix"
      "nixos-system/tailscale.nix"
      "nixos-system/users.nix"
      "nixos-system/sshd.nix"
      "nixos-system/zsh.nix"
      "nixos-system/misc.nix"
      "nixos-system/nixpkgs.nix"
      "nixos-system/backups.nix"
      "nixos-system/sops.nix"
      "nixos-system/nvidia.nix"

      "nixos-system/postgresql.nix"
      "nixos-system/monitoring-server.nix"
      "nixos-system/monitoring-client.nix"
      "nixos-system/traefik.nix"
      "nixos-system/mysql.nix"
      "nixos-system/photoprism.nix" # requires mysql.nix
      "nixos-system/lldap.nix" # requires postgresql.nix
      "nixos-system/uptime-kuma.nix"
      "nixos-system/calibre.nix"
      "nixos-system/nginx-sites.nix"
      "nixos-system/nextcloud.nix" # requires postgresql.nix
      "nixos-system/home-assistant.nix" # requires postgresql.nix
      "nixos-system/authelia-dcbond.nix" # requires lldap.nix
      "nixos-system/stirling-pdf.nix"
      "nixos-system/dcbond-root.nix"
      "nixos-system/oci-containers.nix"
      "nixos-system/oci-fava.nix"
      "nixos-system/oci-media-server.nix" # requires nvidia.nix
      "nixos-system/oci-frigate.nix" # requires nvidia.nix
      "nixos-system/oci-pihole.nix"
      "nixos-system/oci-actual.nix"
      "nixos-system/oci-zwavejs.nix"
      "nixos-system/oci-searxng.nix"
      "nixos-system/oci-recipesage.nix"
      "nixos-system/oci-librechat.nix"
      "nixos-system/oci-unifi.nix"
      "nixos-system/ollama.nix"
      "nixos-system/n8n.nix" # won't build n8n package from source...

      "scripts/media-transfer.nix"
    ])
  ];

}