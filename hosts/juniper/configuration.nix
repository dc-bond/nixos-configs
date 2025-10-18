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
  
  options.hostSpecificConfigs = {
    primaryIp = lib.mkOption {
      type = lib.types.str;
      description = "primary ipv4 address for this host";
    };
    sshdPort = lib.mkOption {
      type = lib.types.int;
      description = "ssh daemon port for this host";
    };
  };

  config = {

    hostSpecificConfigs = {
      primaryIp = configVars.juniperIp;
      sshdPort = 28764;
    };

    networking.hostName = "juniper";

    environment.systemPackages = with pkgs; [
      rsync # sync tool
      btop # system monitor
    ];

    backups.startTime = "*-*-* 01:35:00"; # everyday at 1:35am

    # original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
    system.stateVersion = "24.11";

  };

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "hosts/juniper/disk-config-btrfs.nix"
      "hosts/juniper/hardware-configuration.nix"
      "nixos-system/boot.nix"
      "nixos-system/networking.nix"
      "nixos-system/tailscale.nix"
      "nixos-system/users.nix"
      "nixos-system/sshd.nix"
      "nixos-system/backups.nix"
      "nixos-system/misc.nix"
      "nixos-system/zsh.nix"
      "nixos-system/sops.nix"
      "nixos-system/nixpkgs.nix"
      "nixos-system/oci-containers.nix"
      "nixos-system/postgresql.nix"
      "nixos-system/traefik.nix"
      "nixos-system/matrix-synapse.nix"
    ])
  ];

}