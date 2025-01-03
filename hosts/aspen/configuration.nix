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
      "nixos-system/common/boot.nix"
      "nixos-system/common/misc.nix"
      "nixos-system/common/nixpkgs.nix"
      "nixos-system/common/postgresql.nix"
      "nixos-system/common/oci-containers.nix"
      #"nixos-system/host-specific/aspen/tailscale.nix"
      "nixos-system/host-specific/aspen/users.nix"
      "nixos-system/host-specific/aspen/sshd.nix"
      "nixos-system/host-specific/aspen/sops.nix"
      "nixos-system/host-specific/aspen/networking.nix"
      "nixos-system/host-specific/aspen/borg.nix"
      "nixos-system/host-specific/aspen/traefik.nix"
      "nixos-system/host-specific/aspen/lldap.nix"
      "nixos-system/host-specific/aspen/authelia.nix"
      "nixos-system/host-specific/aspen/oci-pihole.nix"
    ])
  ];

  environment.systemPackages = with pkgs; [
    #(import (configLib.relativeToRoot "scripts/restore-backup.nix") { inherit pkgs config; })
    nvd # package version diff info for nix build operations
    btop # system monitor
    nmap # network scanning
    ethtool # network tools
    gzip # compress/decompress tool
  ];
  
# original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "23.11";

}