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

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "hosts/cypress/disk-config-btrfs.nix"
      "hosts/cypress/hardware-configuration.nix"
      "nixos-system/common/boot.nix"
      "nixos-system/common/misc.nix"
      "nixos-system/common/zsh.nix"
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
      #"nixos-system/common/authelia-dcbond.nix"
      #"nixos-system/common/unifi-controller.nix" # compile problems with mongodb
      "nixos-system/common/oci-pihole.nix"
      "nixos-system/common/oci-actual.nix"
      "nixos-system/common/oci-fava.nix"
      "nixos-system/common/oci-zwavejs.nix"
      "nixos-system/common/oci-recipesage.nix"
      "nixos-system/host-specific/cypress/users.nix"
      "nixos-system/host-specific/cypress/sshd.nix"
      "nixos-system/host-specific/cypress/sops.nix"
      "nixos-system/host-specific/cypress/networking.nix"
      "nixos-system/host-specific/cypress/tailscale.nix"
      "nixos-system/host-specific/cypress/borg-client.nix"
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