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

  environment.systemPackages = with pkgs; [
    nvd # package version diff info for nix build operations
    rsync # sync tool
    git # git
    eza # modern replacement for 'ls'
    pfetch # system info displayed on shell startup
    btop # system monitor
    ethtool # network tools
  ];


  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "hosts/juniper/disk-config-btrfs.nix"
      "hosts/juniper/hardware-configuration.nix"

      #"nixos-system/common/cloud-backups.nix"
      "nixos-system/common/misc.nix"
      "nixos-system/common/zsh.nix"
      "nixos-system/common/sops.nix"
      "nixos-system/common/fonts.nix"
      "nixos-system/common/nixpkgs.nix"
      #"nixos-system/common/oci-containers.nix"
      #"nixos-system/common/lldap.nix" # requires postgresql.nix
      #"nixos-system/common/postgresql.nix"
      #"nixos-system/common/traefik.nix"
      #"nixos-system/common/authelia-dcbond.nix" # requires lldap.nix
      #"nixos-system/common/matrix.nix" # requires postgresql.nix

      #"nixos-system/host-specific/juniper/borg-backups.nix"
      "nixos-system/host-specific/juniper/users.nix"
      "nixos-system/host-specific/juniper/sshd.nix"
      "nixos-system/host-specific/juniper/networking.nix"
      "nixos-system/host-specific/juniper/boot.nix"
      #"nixos-system/host-specific/juniper/tailscale.nix"
    ])
  ];

  # original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "24.11";

}