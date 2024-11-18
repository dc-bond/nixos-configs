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
      "hosts/aspen/disk-config-ext4.nix"
      "hosts/aspen/hardware-configuration.nix"
      "nixos-system/common/misc.nix"
      "nixos-system/common/nixpkgs.nix"
      "nixos-system/host-specific/aspen/tailscale.nix"
      "nixos-system/host-specific/aspen/users.nix"
      "nixos-system/host-specific/aspen/boot.nix"
      "nixos-system/host-specific/aspen/sshd.nix"
      "nixos-system/host-specific/aspen/sops.nix"
      "nixos-system/host-specific/aspen/networking.nix"
      # systemd-nspawn containers
      #"nixos-system/common/nspawn-containers.nix"
      #"nixos-system/common/nspawn-uptime-kuma.nix"
      # docker oci containers
      "nixos-system/common/oci-containers.nix"
      "nixos-system/common/oci-jellyseerr.nix"
      "nixos-system/common/oci-lldap.nix"
      # non-container service modules
      "nixos-system/common/traefik.nix"
      #"nixos-system/common/authelia.nix" # wait until 24.11?
      "nixos-system/common/uptime-kuma.nix"
      "nixos-system/common/nextcloud.nix"
    ])
  ];

  environment.systemPackages = with pkgs; [
    nvd # package version diff info for nix build operations
    btop # system monitor
    nmap # network scanning
    ethtool # network tools
  ];
  
# original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "23.11";

}