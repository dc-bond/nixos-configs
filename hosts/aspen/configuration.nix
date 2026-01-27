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

  config = {

    networking.hostName = "aspen";

    backups = {
      borgDir = "${config.bulkStorage.path}/borgbackup"; # host-specific borg backup directory override on backups.nix
      standaloneData = [
        "${config.bulkStorage.path}/media/family-media"
      ];
    };

    environment.systemPackages = with pkgs; [
      wget # download tool
      usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
      smartmontools # provides smartctl command for disk health monitoring
      rsync # sync tool
      btop # system monitor
    ];

    # weekly btrfs scrubbing for data integrity
    services.btrfs.autoScrub = {
      enable = true;
      interval = "Sun *-*-* 04:00:00";
      fileSystems = [ "/" ];
    };

    # original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
    system.stateVersion = "24.11";

  };

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "hosts/aspen/disk-config.nix"
      "hosts/aspen/hardware-configuration.nix"
      "nixos-system/boot.nix"
      "nixos-system/foundation.nix"
      "nixos-system/networking.nix"
      "nixos-system/crowdsec.nix"
      "nixos-system/tailscale.nix"
      "nixos-system/users.nix"
      "nixos-system/sshd.nix"
      "nixos-system/zsh.nix"
      "nixos-system/backups.nix"
      "nixos-system/sops.nix"
      "nixos-system/nvidia.nix"
      "nixos-system/samba.nix"

      "nixos-system/postgresql.nix"
      "nixos-system/monitoring-client.nix"
      "nixos-system/traefik.nix"
      "nixos-system/mysql.nix"
      "nixos-system/photoprism.nix" # requires mysql.nix
      "nixos-system/lldap.nix" # requires postgresql.nix
      "nixos-system/calibre.nix"
      "nixos-system/nginx-sites.nix"
      "nixos-system/nextcloud.nix" # requires postgresql.nix
      "nixos-system/home-assistant.nix" # requires postgresql.nix
      "nixos-system/authelia-dcbond.nix" # requires lldap.nix
      "nixos-system/stirling-pdf.nix"
      "nixos-system/dcbond-root.nix"
      "nixos-system/ollama.nix"
      "nixos-system/oci-containers.nix"
      "nixos-system/oci-fava.nix"
      "nixos-system/oci-frigate.nix" # requires nvidia.nix
      "nixos-system/oci-pihole.nix"
      "nixos-system/oci-actual.nix"
      "nixos-system/oci-zwavejs.nix"
      "nixos-system/oci-searxng.nix"
      "nixos-system/oci-recipesage.nix"
      "nixos-system/oci-unifi.nix"
      #"nixos-system/oci-finplanner.nix" # requires authelia-dcbond.nix
      "nixos-system/oci-chris-workouts.nix"
      "nixos-system/oci-danielle-workouts.nix"
      "nixos-system/oci-n8n.nix"
      "nixos-system/oci-media-server.nix"

      "scripts/media-transfer.nix"
    ])
  ];

}