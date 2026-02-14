{
  inputs,
  outputs,
  lib,
  configLib,
  configVars,
  config,
  pkgs,
  ...
}:

{

  networking.hostName = "cypress";

  # disko disk configuration
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = configVars.hosts.${config.networking.hostName}.hardware.disk0;
        content = {
          type = "gpt";
          partitions = {

            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/persist" = {
                    mountpoint = "/persist";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/snapshots" = { # to be implemented on next fresh installation
                    mountpoint = "/snapshots";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/swap" = {
                    mountpoint = "/swap";
                    swap.swapfile.size = "8G"; # 0.5x RAM - adequate OOM protection without hibernation
                  };
                };
              };
            };

          };
        };
      };
    };
  };

  ## Western Digital 4TB USB HDD Serial WD-WX21DC86RU3P
  #bulkStorage.path = "/storage";

  #fileSystems."/storage" = {
  #  device = "/dev/disk/by-uuid/f3fb53cc-52fa-48e3-8cac-b69d85a8aff1";
  #  fsType = "ext4";
  #  options = [
  #    "defaults"  # standard mount options
  #    "nofail"    # don't fail boot if drive is unplugged
  #    "noatime"   # don't update access times (better performance, less wear)
  #  ];
  #};

  environment.systemPackages = with pkgs; [
    age # encryption tool
    mkpasswd # password hashing tool
    dig # dns lookup tool
    wget # download tool
    rsync # sync tool
    jq # json parser tool
    usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
    smartmontools # provides smartctl command for disk health monitoring
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

  hardware.i2c.enable = true; # enable i2c kernel module for ddcutil functionality

  backups = {
    prune.daily = 3; # workstation retention: 3 daily archives reduces borg compact segment rewrites, keeping rclone cloud syncs incremental
  };

  btrfs.snapshots = true; # enable hourly + recovery snapshots and recoverSnap script

  # original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "23.11";

  imports = lib.flatten [
    inputs.disko.nixosModules.disko
    (map configLib.relativeToRoot [
      "hosts/cypress/hardware-configuration.nix"
      "hosts/cypress/impermanence.nix"
      "nixos-system/boot.nix"
      "nixos-system/foundation.nix"
      "nixos-system/rebuilds.nix"
      "nixos-system/networking.nix"
      "nixos-system/tailscale.nix"
      "nixos-system/users.nix"
      "nixos-system/sshd.nix"
      "nixos-system/audio.nix"
      "nixos-system/zsh.nix"
      "nixos-system/yubikey.nix"
      "nixos-system/printing.nix"
      "nixos-system/backups.nix"
      "nixos-system/btrfs.nix"
      "nixos-system/sops.nix"
      "nixos-system/bluetooth.nix"
      "nixos-system/monitoring-client.nix"
      "nixos-system/usb-phone-mount.nix"

      "nixos-system/greetd.nix"
      "nixos-system/hyprland.nix"

      "scripts/deploy.nix"
    ])
  ];

}