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

  networking.hostName = "thinkpad";

  disko.devices = {
    disk = {
      disk0 = {
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
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                settings = {
                  allowDiscards = true;
                };
                passwordFile = "/tmp/crypt-passwd.txt"; # interactive login
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
                      swap.swapfile.size = "8G"; # cold-page overflow behind zram; larger than RAM is fine — no hibernation on impermanence hosts
                    };
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

  backups = {
    startTime = "*-*-* 02:40:00"; # staggered: thinkpad at 2:40 AM
    prune.daily = 3; # workstation retention: 3 daily archives reduces borg compact segment rewrites, keeping rclone cloud syncs incremental
  };

  # enable nix-ld to run dynamically linked binaries (e.g., vscodium extensions)
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
    ];
  };

  services.logind.settings.Login.HandleLidSwitch = "ignore"; # disable suspend on laptop lid close

  # original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "25.11";

  imports = lib.flatten [
    inputs.disko.nixosModules.disko
    (map configLib.relativeToRoot [
      "hosts/thinkpad/hardware-configuration.nix"
      "hosts/thinkpad/impermanence.nix"
      "nixos-system/boot.nix"
      "nixos-system/foundation.nix"
      "nixos-system/base-tools.nix"
      "nixos-system/rebuilds.nix"
      "nixos-system/networking.nix"
      "nixos-system/tailscale.nix" # recoverTailscale
      "nixos-system/users.nix"
      "nixos-system/sshd.nix"
      "nixos-system/audio.nix"
      "nixos-system/zsh.nix"
      "nixos-system/workstation-tools.nix"
      "nixos-system/yubikey.nix"
      "nixos-system/printing.nix"
      "nixos-system/backups.nix"
      "nixos-system/btrfs.nix"
      "nixos-system/sops.nix"
      "nixos-system/bluetooth.nix"
      "nixos-system/monitoring-client.nix"
      "nixos-system/usb-phone-mount.nix"
      "nixos-system/wd-passport.nix"
      "nixos-system/intel.nix"
      "nixos-system/oom.nix"
      "nixos-system/zram.nix"
      "nixos-system/greetd.nix"
      "nixos-system/ddcutil.nix"
      "nixos-system/hyprland.nix"
      "scripts/deploy.nix"
      "scripts/network-test.nix"
    ])
  ];

}
