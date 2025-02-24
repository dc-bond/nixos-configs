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

  fileSystems."/media/WD-WX21DC86RU3P" = {
    device = "/dev/disk/by-uuid/f3fb53cc-52fa-48e3-8cac-b69d85a8aff1";
    fsType = "ext4"; 
    options = [ "defaults" ];
  };

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "hosts/${config.networking.hostName}/disk-config-btrfs.nix"
      "hosts/${config.networking.hostName}/hardware-configuration.nix"
      "nixos-system/common/cloud-backups.nix"
      "nixos-system/common/boot.nix"
      "nixos-system/common/misc.nix"
      "nixos-system/common/zsh.nix"
      "nixos-system/common/sops.nix"
      "nixos-system/common/fonts.nix"
      "nixos-system/common/nixpkgs.nix"
      "nixos-system/common/oci-containers.nix"
      "nixos-system/common/mosquitto.nix"
      "nixos-system/common/uptime-kuma.nix"
      "nixos-system/common/lldap.nix"
      "nixos-system/common/postgresql.nix"
      "nixos-system/common/traefik.nix"
      "nixos-system/common/nextcloud.nix"
      "nixos-system/common/home-assistant.nix"
      "nixos-system/common/authelia-dcbond.nix"
      "nixos-system/common/stirling-pdf.nix"
      "nixos-system/common/matrix.nix"
      "nixos-system/common/privatebin.nix"
      "nixos-system/common/dcbond-root.nix"
      #"nixos-system/common/unifi-controller.nix" # compile problems with mongodb
      "nixos-system/common/oci-media-server.nix"
      "nixos-system/common/oci-unifi-controller.nix"
      "nixos-system/common/oci-pihole.nix"
      "nixos-system/common/oci-actual.nix"
      "nixos-system/common/oci-fava.nix"
      "nixos-system/common/oci-zwavejs.nix"
      "nixos-system/common/oci-chromium.nix"
      "nixos-system/common/oci-searxng.nix"
      #"nixos-system/common/oci-wordpress-dcbond.nix"
      #"nixos-system/common/oci-recipesage.nix"
      "nixos-system/host-specific/${config.networking.hostName}/borg-backups.nix"
      "nixos-system/host-specific/${config.networking.hostName}/users.nix"
      "nixos-system/host-specific/${config.networking.hostName}/sshd.nix"
      "nixos-system/host-specific/${config.networking.hostName}/networking.nix"
      "nixos-system/host-specific/${config.networking.hostName}/tailscale.nix"
    ])
  ];

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

}