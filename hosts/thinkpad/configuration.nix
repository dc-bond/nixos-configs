# MANUAL SETUP ON FRESH INSTALL
#run "gpg --card-status" to register yubikey
#clone nixos-configs and pass repos using ssh
#bluetooth connect mouse (bluetoothctl, press pairing button, scan on, pair xx:xx, trust xx:xx, update script?)
#nextcloud-client setup (keyring passwd?)
#firefox setup (activate extensions, etc.)
#vscode github authentication
#vscode extension setup
#tailscale auth key - remove old machine, generate new key in console, replace in secrets.yaml - key non-reusable, 90-day expiration, pre-authorized, non-ephemeral, update new tailscale IP in conficVars

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
      primaryIp = configVars.thinkpadLanIp;
      sshdPort = 28765;
    };

    networking.hostName = "thinkpad";

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
      nmap # network scanning
      #wgnord # nordvpn
      brightnessctl # screen brightness application
      ddcutil # query and change monitor settings using DDC/CI and USB
      i2c-tools # hardware interface tools required by ddcutil
    ];

    #backups.startTime = "*-*-* 01:05:00"; # everyday at 1:05am
    #services.borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter [ "${config.users.users.chris.home}/email" ];

    hardware.i2c.enable = true; # enable i2c kernel module for ddcutil functionality

    services.logind.lidSwitch = "ignore"; # disable suspend on laptop lid close

    # original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
    system.stateVersion = "23.11";

  };

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "hosts/thinkpad/disk-config-btrfs-luks.nix"
      "hosts/thinkpad/hardware-configuration.nix"
      
      "nixos-system/common/boot.nix"
      "nixos-system/common/networking.nix"
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
      "nixos-system/common/keyring.nix"
      "nixos-system/common/bluetooth.nix"
      
      #"nixos-system/common/display-manager.nix"
      "nixos-system/common/hyprland.nix"
      #"nixos-system/common/plasma.nix"

      "nixos-system/host-specific/thinkpad/users.nix"
      "nixos-system/host-specific/thinkpad/tailscale.nix"

      "scripts/deploy-aspen.nix"
      "scripts/deploy-cypress.nix"
      "scripts/deploy-juniper.nix"
    ])
  ];

}