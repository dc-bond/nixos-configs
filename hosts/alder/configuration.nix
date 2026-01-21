## MANUAL SETUP PRE- FRESH INSTALL ##
# update configVars to add host and users
# update configuration.nix, disko configs, home.nix, 
# update greetd.nix default cmd
# add host and user age keys to sops.yaml, update keys on secrets.yaml (see notes in sops.yaml)
# add user(s) hashed password to secrets.yaml
# add user(s) password to pass repo
# tailscale auth key - generate new key in console, add to secrets.yaml - key non-reusable, 90-day expiration, pre-authorized, non-ephemeral, add new tailscale IP in configVars
# update monitoring server configs to add node
## MANUAL SETUP POST- FRESH INSTALL ##
# first time wifi and tailscale connection
# tailscale disable expiry in console
# first time bluetooth devices setup
# firefox setup (activate extensions, etc.)

{ 
  inputs, 
  outputs, 
  lib, 
  configLib,
  config, 
  configVars,
  pkgs, 
  ... 
}: 

{

  systemd.services.tailscaled.restartIfChanged = false;
  systemd.services.iwd.restartIfChanged = false;
  
  networking.hostName = "alder";

  environment.systemPackages = with pkgs; [
    age # encryption tool
    mkpasswd # password hashing tool
    dig # dns lookup tool
    wget # download tool
    rsync # sync tool
    usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
    nix-tree # table view of package dependencies
    ethtool # network tools
    inetutils # more network tools like telnet
    zip # zip compression utility
    unzip # utility to unzip directories
    btop # system monitor
    nmap # network scanning
    brightnessctl # screen brightness application
    ddcutil # query and change monitor settings using DDC/CI and USB
    i2c-tools # hardware interface tools required by ddcutil
  ];

  #backups.startTime = "*-*-* 01:05:00"; # everyday at 1:05am
  #services.borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter [ "${config.users.users.eric.home}/email" ];

  hardware.i2c.enable = true; # enable i2c kernel module for ddcutil functionality

  services.logind.settings.Login.HandleLidSwitch = "ignore"; # disable suspend on laptop lid close

  # original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "25.05";

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "hosts/alder/disk-config-btrfs-luks.nix"
      "hosts/alder/hardware-configuration.nix"
      "nixos-system/boot.nix"
      "nixos-system/foundation.nix"
      "nixos-system/networking.nix"
      "nixos-system/tailscale.nix"
      "nixos-system/users.nix"
      "nixos-system/sshd.nix"
      "nixos-system/audio.nix"
      "nixos-system/zsh.nix"
      #"nixos-system/printing.nix"
      #"nixos-system/backups.nix"
      "nixos-system/sops.nix"
      "nixos-system/bluetooth.nix"
      "nixos-system/monitoring-client.nix"
      
      "nixos-system/greetd.nix"
      "nixos-system/labwc.nix"
    ])
  ];

}