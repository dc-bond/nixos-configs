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
  
  config = {
    
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
      "nixos-system/boot.nix"
      "nixos-system/networking.nix"
      "nixos-system/tailscale.nix"
      "nixos-system/users.nix"
      "nixos-system/sshd.nix"
      "nixos-system/audio.nix"
      "nixos-system/zsh.nix"
      "nixos-system/fonts.nix"
      "nixos-system/yubikey.nix"
      "nixos-system/printing.nix"
      "nixos-system/misc.nix"
      "nixos-system/nixpkgs.nix"
      #"nixos-system/backups.nix"
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