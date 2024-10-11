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
      "nixos-system/common/nixpkgs.nix"
      "nixos-system/host-specific/vm1/users.nix"
      "nixos-system/host-specific/vm1/sshd.nix"
      "nixos-system/host-specific/vm1/sops.nix"
      "nixos-system/host-specific/vm1/networking.nix"
    ])
  ];

  environment.systemPackages = with pkgs; [
    (import (configLib.relativeToRoot "scripts/hello-world.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/deployThinkpad.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/deployAspen.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/getPassRepo.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/rebuildLocalVm1.nix") { inherit pkgs config; })
    age # encryption tool
    sops # secrets management tool that can use different types of encryption (e.g. age, pgp, etc.)
    wget # download tool
    usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
    nvd # package version diff info for nix build operations
    nix-tree # table view of package dependencies
    ethtool # network tools
    unzip # utility to unzip directories
    git # git
    eza # modern replacement for 'ls'
    pfetch # system info displayed on shell startup
    btop # system monitor
    nmap # network scanning
  ];

# original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "23.11";

}