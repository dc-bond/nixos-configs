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
      "hosts/vm1/disk-config-btrfs-luks.nix"
      "hosts/vm1/hardware-configuration.nix"
      "nixos-system/common/misc.nix"
      "nixos-system/common/boot.nix"
      "nixos-system/common/zsh.nix"
      "nixos-system/common/fonts.nix"
      "nixos-system/common/yubikey.nix"
      "nixos-system/common/packages.nix"
      "nixos-system/host-specific/vm1/users.nix"
      "nixos-system/host-specific/vm1/nixpkgs.nix"
      "nixos-system/host-specific/vm1/sshd.nix"
      "nixos-system/host-specific/vm1/sops.nix"
      "nixos-system/host-specific/vm1/networking.nix"
      "nixos-system/host-specific/vm1/packages.nix"
    ])
  ];

# original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "23.11";

}