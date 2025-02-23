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
      "nixos-system/common/cloud-backups.nix"
      "nixos-system/host-specific/thinkpad/login.nix"
      "nixos-system/host-specific/thinkpad/users.nix"
      "nixos-system/host-specific/thinkpad/keyring.nix"
      "nixos-system/host-specific/thinkpad/sshd.nix"
      "nixos-system/host-specific/thinkpad/sops.nix"
      "nixos-system/host-specific/thinkpad/bluetooth.nix"
      "nixos-system/host-specific/thinkpad/networking.nix"
      "nixos-system/host-specific/thinkpad/tailscale.nix"
      "nixos-system/host-specific/thinkpad/borg-backups.nix"
      "nixos-system/host-specific/thinkpad/lsyncd.nix"
      "scripts/backup-recovery/info-cypress-archives.nix"
      "scripts/backup-recovery/recover-traefik.nix"
      "scripts/backup-recovery/recover-homeassistant.nix"
      "scripts/backup-recovery/recover-matrix.nix"
      "scripts/backup-recovery/recover-nextcloud.nix"
      "scripts/backup-recovery/recover-uptime-kuma.nix"
      "scripts/backup-recovery/recover-zwavejs.nix"
      "scripts/backup-recovery/recover-media-server.nix"
      "scripts/backup-recovery/recover-lldap.nix"
      "scripts/backup-recovery/recover-searxng.nix"
      "scripts/backup-recovery/recover-chromium.nix"
      "scripts/backup-recovery/recover-actual.nix"
      "scripts/backup-recovery/recover-pihole.nix"
      "scripts/backup-recovery/recover-unifi-controller.nix"
      #"scripts/backup-recovery/recover-recipesage.nix"
      "scripts/rebuild-remote-cypress.nix"
    ])
  ];

  environment.systemPackages = with pkgs; [
    (import (configLib.relativeToRoot "scripts/deploy-aspen.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/deploy-cypress.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/get-pass-repo.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/setup-borg-sshkeys.nix") { inherit pkgs config; })
    (import (configLib.relativeToRoot "scripts/rebuild-local-thinkpad.nix") { inherit pkgs config; })
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
    hollywood # fill terminal with melodramatic technobabble
    cool-retro-term # retro terminal
    filelight # disk usage visualizer
  ];

  hardware.i2c.enable = true; # enable i2c kernel module for ddcutil functionality

  services.logind.lidSwitch = "ignore"; # disable suspend on laptop lid close

# original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "23.11";

}