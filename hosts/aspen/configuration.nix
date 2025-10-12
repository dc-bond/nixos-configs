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
  };

  config = {

    hostSpecificConfigs = {
      storageDrive1 = "/storage/WD-WCC7K4RU947F";
      primaryIp = configVars.aspenLanIp;
      sshdPort = 28766;
    };

    fileSystems."${config.hostSpecificConfigs.storageDrive1}" = {
      device = "/dev/disk/by-uuid/2dbedc67-9a6b-477f-a3b4-75116994d1cb";
      fsType = "ext4"; 
      options = [ "defaults" ];
    };

    backups = {
      borgDir = "${config.hostSpecificConfigs.storageDrive1}/borgbackup"; # host-specific borg backup directory override on backups.nix
      #startTime = ""; # default to everyday at 12:45am declared in backups.nix
    };

    services.borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter [ "${config.hostSpecificConfigs.storageDrive1}/media/family-media" ]; # backup media directory outside of any individual service backup context

    environment.systemPackages = with pkgs; [
      wget # download tool
      usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
      rsync # sync tool
      git # git
      dig # dns lookup tool
      btop # system monitor
    ];

    # original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
    system.stateVersion = "24.11";

  };

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "hosts/aspen/disk-config-btrfs.nix"
      "hosts/aspen/hardware-configuration.nix"
      
      "nixos-system/common/sshd.nix"
      "nixos-system/common/zsh.nix"
      "nixos-system/common/misc.nix"
      "nixos-system/common/nixpkgs.nix"
      "nixos-system/common/backups.nix"
      "nixos-system/common/sops.nix"
      "nixos-system/common/nvidia.nix"

      "nixos-system/host-specific/aspen/boot.nix"
      "nixos-system/host-specific/aspen/networking.nix"
      "nixos-system/host-specific/aspen/tailscale.nix"
      "nixos-system/host-specific/aspen/users.nix"
      
      "nixos-system/common/postgresql.nix"
      "nixos-system/common/traefik.nix"
      "nixos-system/common/mysql.nix"
      "nixos-system/common/photoprism.nix" # requires mysql.nix
      "nixos-system/common/lldap.nix" # requires postgresql.nix
      "nixos-system/common/uptime-kuma.nix"
      "nixos-system/common/calibre.nix"
      "nixos-system/common/nginx-sites.nix"
      "nixos-system/common/nextcloud.nix" # requires postgresql.nix
      "nixos-system/common/home-assistant.nix" # requires postgresql.nix
      "nixos-system/common/authelia-dcbond.nix" # requires lldap.nix
      "nixos-system/common/stirling-pdf.nix"
      "nixos-system/common/dcbond-root.nix"
      "nixos-system/common/oci-containers.nix"
      "nixos-system/common/oci-fava.nix"
      "nixos-system/common/oci-media-server.nix" # requires nvidia.nix
      "nixos-system/common/oci-frigate.nix" # requires nvidia.nix
      "nixos-system/common/oci-pihole.nix"
      "nixos-system/common/oci-actual.nix"
      "nixos-system/common/oci-zwavejs.nix"
      "nixos-system/common/oci-searxng.nix"
      "nixos-system/common/oci-recipesage.nix"
      "nixos-system/common/oci-librechat.nix"
      "nixos-system/common/oci-unifi.nix"
      "nixos-system/common/ollama.nix"
      #"nixos-system/common/n8n.nix" # won't build n8n package from source...

      "scripts/media-transfer.nix"
    ])
  ];

}