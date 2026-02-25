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

  hardware.i2c.enable = true; # enable i2c kernel module for ddcutil functionality

  backups = {
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