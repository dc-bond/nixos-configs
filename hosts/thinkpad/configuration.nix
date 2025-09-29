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
    #(import (configLib.relativeToRoot "scripts/get-pass-repo.nix") { inherit pkgs config; })
    age # encryption tool
    mkpasswd # password hashing tool
    dig # dns lookup tool
    sops # secrets management tool that can use different types of encryption (e.g. age, pgp, etc.)
    wget # download tool
    rsync # sync tool
    usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
    nvd # package version diff info for nix build operations
    nix-tree # table view of package dependencies
    ethtool # network tools
    inetutils # more network tools like telnet
    unzip # utility to unzip directories
    git # git
    eza # modern replacement for 'ls'
    pfetch # system info displayed on shell startup
    btop # system monitor
    nmap # network scanning
    brightnessctl # screen brightness application
    ddcutil # query and change monitor settings using DDC/CI and USB
    i2c-tools # hardware interface tools required by ddcutil
    libreoffice-still # office suite
    element-desktop # matrix chat app
    feh # simple image viewer
    wgnord # nordvpn
    openssl # openssl command line tool
  ];

  backups.startTime = "*-*-* 02:45:00"; # everyday at 2:45am

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "hosts/thinkpad/disk-config-btrfs-luks.nix"
      "hosts/thinkpad/hardware-configuration.nix"
      
      "nixos-system/common/audio.nix"
      "nixos-system/common/boot.nix"
      "nixos-system/common/zsh.nix"
      "nixos-system/common/fonts.nix"
      "nixos-system/common/yubikey.nix"
      "nixos-system/common/thunar.nix"
      "nixos-system/common/hyprland.nix"
      "nixos-system/common/printing.nix"
      "nixos-system/common/misc.nix"
      "nixos-system/common/nixpkgs.nix"
      "nixos-system/common/backups.nix"
      "nixos-system/common/sops.nix"
      "nixos-system/common/keyring.nix"
      "nixos-system/common/login.nix"
      "nixos-system/common/bluetooth.nix"
      "nixos-system/common/firejail.nix"

      "nixos-system/host-specific/thinkpad/users.nix"
      "nixos-system/host-specific/thinkpad/sshd.nix"
      "nixos-system/host-specific/thinkpad/networking.nix"
      "nixos-system/host-specific/thinkpad/tailscale.nix"

      "scripts/deploy-aspen.nix"
      "scripts/deploy-cypress.nix"
      "scripts/deploy-juniper.nix"
    ])
  ];

  hardware.i2c.enable = true; # enable i2c kernel module for ddcutil functionality

  services.logind.lidSwitch = "ignore"; # disable suspend on laptop lid close

# original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "23.11";

}