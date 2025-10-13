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
    storageDrive1 = lib.mkOption {
      type = lib.types.path;
      description = "path to storage drive 1";
    };
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
      storageDrive1 = "/storage/WD-WX21DC86RU3P";
      primaryIp = configVars.cypressLanIp;
      sshdPort = 28761;
    };

    fileSystems."${config.hostSpecificConfigs.storageDrive1}" = {
      device = "/dev/disk/by-uuid/f3fb53cc-52fa-48e3-8cac-b69d85a8aff1";
      fsType = "ext4"; 
      options = [ "defaults" ];
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
      unzip # utility to unzip directories
      btop # system monitor
    ];

    #backups.startTime = "*-*-* 02:45:00"; # everyday at 2:45am

    # original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
    system.stateVersion = "23.11";

  };

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "hosts/cypress/disk-config-btrfs.nix"
      "hosts/cypress/hardware-configuration.nix"

      "nixos-system/common/sshd.nix"
      "nixos-system/common/audio.nix"
      "nixos-system/common/zsh.nix"
      "nixos-system/common/fonts.nix"
      "nixos-system/common/yubikey.nix"
      "nixos-system/common/printing.nix"
      "nixos-system/common/misc.nix"
      "nixos-system/common/nixpkgs.nix"
      #"nixos-system/common/backups.nix"
      "nixos-system/common/sops.nix"

      "nixos-system/host-specific/cypress/boot.nix"
      "nixos-system/host-specific/cypress/users.nix"
      "nixos-system/host-specific/cypress/networking.nix"
      "nixos-system/host-specific/cypress/tailscale.nix"

      "scripts/deploy-thinkpad.nix"
    ])
  ];

}