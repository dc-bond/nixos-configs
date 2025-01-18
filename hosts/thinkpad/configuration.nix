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
      "nixos-system/common/backblaze.nix"
      "nixos-system/host-specific/thinkpad/login.nix"
      "nixos-system/host-specific/thinkpad/users.nix"
      "nixos-system/host-specific/thinkpad/keyring.nix"
      "nixos-system/host-specific/thinkpad/sshd.nix"
      "nixos-system/host-specific/thinkpad/sops.nix"
      "nixos-system/host-specific/thinkpad/bluetooth.nix"
      "nixos-system/host-specific/thinkpad/networking.nix"
      "nixos-system/host-specific/thinkpad/tailscale.nix"
      "nixos-system/host-specific/thinkpad/borg.nix"
    ])
  ];

  environment.systemPackages = with pkgs; [
    (import (configLib.relativeToRoot "scripts/backup-recovery-hass.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/backup-recovery-zwavejs.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/backup-recovery-lldap.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/backup-recovery-traefik.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/backup-recovery-authelia-opticon.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/backup-recovery-nextcloud.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/deploy-aspen.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/deploy-cypress.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/get-pass-repo.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/setup-borg-sshkeys.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/rebuild-local-thinkpad.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/rebuild-remote-cypress.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/rebuild-remote-aspen.nix") { inherit pkgs config; })
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
    #element-desktop-wayland # matrix chat app
    #drawio # diagram drawing app
  ];

  hardware.i2c.enable = true; # enable i2c kernel module for ddcutil functionality

  services.logind.lidSwitch = "ignore"; # disable suspend on laptop lid close

# original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "23.11";

}