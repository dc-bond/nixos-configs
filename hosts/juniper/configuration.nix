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

  networking.hostName = "juniper";

  # disko disk configuration
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = configVars.hosts.${config.networking.hostName}.hardware.btrfsOsDisk;
        content = {
          type = "gpt";
          partitions = {

            bios-grub = {
              size = "2M";
              type = "EF02";
            };

            root = {
              size = "100%";
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
                    swap.swapfile.size = "8G";
                  };
                };
              };
            };

          };
        };
      };
    };
  };

  backups.borgDir = "/var/lib/borgbackup"; # juniper does not use impermanence

  environment.systemPackages = with pkgs; [
    rsync # sync tool
    btop # system monitor
  ];

  # original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "24.11";

  imports = lib.flatten [
    inputs.disko.nixosModules.disko
    (map configLib.relativeToRoot [
      "hosts/juniper/hardware-configuration.nix"
      "nixos-system/boot.nix"
      "nixos-system/foundation.nix"
      "nixos-system/networking.nix"
      "nixos-system/crowdsec.nix"
      "nixos-system/tailscale.nix"
      "nixos-system/users.nix"
      "nixos-system/sshd.nix"
      "nixos-system/backups.nix"
      "nixos-system/btrfs.nix"
      "nixos-system/zsh.nix"
      "nixos-system/sops.nix"
      "nixos-system/monitoring-server.nix"
      "nixos-system/oci-containers.nix"
      "nixos-system/oci-pihole.nix"
      "nixos-system/postgresql.nix"
      "nixos-system/traefik.nix"
      "nixos-system/matrix.nix"
      "nixos-system/vaultwarden.nix"
      "nixos-system/homepage.nix"
    ])
  ];

}