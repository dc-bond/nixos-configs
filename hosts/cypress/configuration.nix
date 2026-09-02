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

  disko.devices = {
    disk = {
      main = {
      #disk0 = {
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

  bulkStorage.path = lib.mkIf (config.hardware.wdPassport.enable or false) "/storage-ext4-external";

  # enable nix-ld to run dynamically linked binaries (e.g., vscodium extensions)
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
    ];
  };

  backups = {
    startTime = "*-*-* 02:45:00"; # staggered: cypress at 2:45 AM
    prune.daily = 3; # workstation retention: 3 daily archives reduces borg compact segment rewrites, keeping rclone cloud syncs incremental
    standaloneData = [ "/home/chris/nixos" ];
    serviceHooks.preHook = [
      # sync nixos configs to nextcloud as tertiary backup (excludes .git to avoid sync corruption)
      "mkdir -p /home/chris/nextcloud-client/Personal/nixos-backup"
      "${pkgs.rsync}/bin/rsync -av --delete --exclude='.git' /home/chris/nixos/ /home/chris/nextcloud-client/Personal/nixos-backup/"
    ];
  };

  # original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "25.11";

  imports = lib.flatten [
    inputs.disko.nixosModules.disko
    (map configLib.relativeToRoot [
      "hosts/cypress/hardware-configuration.nix"
      "hosts/cypress/impermanence.nix"
      "nixos-system/boot.nix"
      "nixos-system/foundation.nix"
      "nixos-system/base-tools.nix"
      "nixos-system/intel.nix"
      "nixos-system/rebuilds.nix"
      "nixos-system/networking.nix"
      "nixos-system/tailscale.nix" # recoverTailscale
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
      "nixos-system/wd-passport.nix"
      "nixos-system/greetd.nix"
      "nixos-system/ddcutil.nix"
      "nixos-system/hyprland.nix"
      "scripts/deploy.nix"
      "scripts/network-test.nix"
      "scripts/test-builds.nix"
    ])
  ];

}
