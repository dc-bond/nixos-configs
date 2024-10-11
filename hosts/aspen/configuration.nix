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
      "hosts/vm1/disk-config-ext4.nix"
      "hosts/vm1/hardware-configuration.nix"
      "nixos-system/common/misc.nix"
      "nixos-system/common/boot.nix"
      "nixos-system/common/zsh.nix"
      "nixos-system/common/fonts.nix"
      "nixos-system/common/nixpkgs.nix"
      "nixos-system/host-specific/aspen/users.nix"
      "nixos-system/host-specific/aspen/sshd.nix"
      "nixos-system/host-specific/aspen/sops.nix"
      "nixos-system/host-specific/aspen/networking.nix"
    ])
  ];

  environment.systemPackages = with pkgs; [
    age # encryption tool
    sops # secrets management tool that can use different types of encryption (e.g. age, pgp, etc.)
    wget # download tool
    nvd # package version diff info for nix build operations
    eza # modern replacement for 'ls'
    pfetch # system info displayed on shell startup
    btop # system monitor
    cowsay
  ];

# original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "23.11";

}