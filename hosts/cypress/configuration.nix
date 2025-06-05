{ 
  inputs, 
  outputs, 
  lib, 
  configLib,
  config, 
  pkgs, 
  ... 
}: 

{

  options.drives = {
    storageDrive1 = lib.mkOption {
      type = lib.types.path;
      default = "/storage/WD-WX21DC86RU3P";
      description = "path to storage drive 1";
    };
  };

  config = {

    fileSystems."${config.drives.storageDrive1}" = {
      device = "/dev/disk/by-uuid/f3fb53cc-52fa-48e3-8cac-b69d85a8aff1";
      fsType = "ext4"; 
      options = [ "defaults" ];
    };

    environment.systemPackages = with pkgs; [
      wget # download tool
      usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
      nvd # package version diff info for nix build operations
      rsync # sync tool
      git # git
      dig # dns lookup tool
      eza # modern replacement for 'ls'
      pfetch # system info displayed on shell startup
      btop # system monitor
      nmap # network scanning
      ethtool # network tools
    ];

    # original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
    system.stateVersion = "23.11";

  };

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "hosts/cypress/disk-config-btrfs.nix"
      "hosts/cypress/hardware-configuration.nix"
      "nixos-system/common/cloud-backups.nix"
      "nixos-system/common/boot.nix"
      "nixos-system/common/misc.nix"
      "nixos-system/common/zsh.nix"
      "nixos-system/common/sops.nix"
      "nixos-system/common/fonts.nix"
      "nixos-system/common/nixpkgs.nix"
      "nixos-system/common/oci-containers.nix"
      "nixos-system/common/mosquitto.nix"
      #"nixos-system/common/uptime-kuma.nix"
      #"nixos-system/common/lldap.nix" # requires postgresql.nix
      "nixos-system/common/postgresql.nix"
      "nixos-system/common/traefik.nix"
      #"nixos-system/common/nextcloud.nix" # requires postgresql.nix
      "nixos-system/common/home-assistant.nix" # requires postgresql.nix, mosquitto.nix
      #"nixos-system/common/authelia-dcbond.nix" # requires lldap.nix
      #"nixos-system/common/stirling-pdf.nix"
      #"nixos-system/common/roundcube.nix" # requires postgresl.nix
      #"nixos-system/common/matrix.nix" # requires postgresql.nix
      #"nixos-system/common/privatebin.nix"
      #"nixos-system/common/dcbond-root.nix"
      #"nixos-system/common/unifi-controller.nix" # compile problems with mongodb
      "nixos-system/common/oci-unifi-controller.nix"
      "nixos-system/common/oci-pihole.nix"
      #"nixos-system/common/oci-actual.nix"
      "nixos-system/common/oci-zwavejs.nix"
      #"nixos-system/common/oci-chromium.nix"
      #"nixos-system/common/oci-searxng.nix"
      #"nixos-system/common/oci-wordpress-dcbond.nix"
      #"nixos-system/common/oci-recipesage.nix"
      #"nixos-system/common/oci-librechat.nix"
      "nixos-system/host-specific/cypress/borg-backups.nix"
      "nixos-system/host-specific/cypress/users.nix"
      "nixos-system/host-specific/cypress/sshd.nix"
      "nixos-system/host-specific/cypress/networking.nix"
      "nixos-system/host-specific/cypress/tailscale.nix"
      "nixos-system/host-specific/cypress/journal2gelf.nix"
    ])
  ];

}