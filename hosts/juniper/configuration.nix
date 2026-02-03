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
  
  config = {

    networking.hostName = "juniper";

    environment.systemPackages = with pkgs; [
      rsync # sync tool
      btop # system monitor
    ];

    # weekly btrfs scrubbing for data integrity
    services.btrfs.autoScrub = {
      enable = true;
      interval = "Sun *-*-* 04:00:00";
      fileSystems = [ "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_103227147-part2" ]; # vps virtual disk partition
    };

    # original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
    system.stateVersion = "24.11";

  };

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "hosts/juniper/disk-config.nix"
      "hosts/juniper/hardware-configuration.nix"
      "nixos-system/boot.nix"
      "nixos-system/foundation.nix"
      "nixos-system/networking.nix"
      "nixos-system/crowdsec.nix"
      "nixos-system/tailscale.nix"
      "nixos-system/users.nix"
      "nixos-system/sshd.nix"
      "nixos-system/backups.nix"
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