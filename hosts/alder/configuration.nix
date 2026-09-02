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

  networking.hostName = "alder";

  disko.devices = {
    disk = {
      main = {
      #disk0 = {
        type = "disk";
        device = "/dev/sda"; # TODO: Change to configVars reference after adding disk0 to vars/default.nix
        # device = configVars.hosts.${config.networking.hostName}.hardware.disk0;
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
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/swap" = {
                      mountpoint = "/swap";
                      swap.swapfile.size = "2G"; # 0.5x RAM - adequate OOM protection without hibernation
                    };

                    #"/nix" = {
                    #  mountpoint = "/nix";
                    #  mountOptions = [ "compress=zstd" "noatime" ];
                    #};
                    #"/persist" = {
                    #  mountpoint = "/persist";
                    #  mountOptions = [ "compress=zstd" "noatime" ];
                    #};
                    #"/swap" = {
                    #  mountpoint = "/swap";
                    #  swap.swapfile.size = "2G"; # 0.5x RAM - adequate OOM protection without hibernation
                    #};
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  systemd.services = {
    tailscaled.restartIfChanged = false;
    iwd.restartIfChanged = false;
  };

  backups = {
    startTime = "*-*-* 02:55:00"; # staggered: alder at 2:55 AM
    prune.daily = 3; # workstation retention: 3 daily archives reduces borg compact segment rewrites, keeping rclone cloud syncs incremental
  };

  services.logind.settings.Login.HandleLidSwitch = "ignore"; # disable suspend on laptop lid close

  # original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "25.05";

  imports = lib.flatten [
    inputs.disko.nixosModules.disko
    (map configLib.relativeToRoot [
      "hosts/alder/hardware-configuration.nix"
      #"hosts/alder/impermanence.nix" # FRESH INSTALL ONLY - uncomment on fresh install
      "nixos-system/boot.nix"
      "nixos-system/foundation.nix"
      "nixos-system/base-tools.nix"
      "nixos-system/networking.nix"
      "nixos-system/tailscale.nix"
      "nixos-system/users.nix"
      "nixos-system/sshd.nix"
      "nixos-system/audio.nix"
      "nixos-system/zsh.nix"
      "nixos-system/backups.nix"
      #"nixos-system/btrfs.nix" # FRESH INSTALL ONLY - uncomment on fresh install
      "nixos-system/sops.nix"
      "nixos-system/bluetooth.nix"
      "nixos-system/monitoring-client.nix"

      "nixos-system/greetd.nix"
      "nixos-system/labwc.nix"
    ])
  ];

}
