## MANUAL SETUP PRE- FRESH INSTALL ##
# update master flake.nix to add host
# update configuration.nix, disko configs, home.nix, 
# update users.nix, greetd.nix
# update configVars
# add host and user age keys to sops.yaml, update keys on secrets.yaml (see notes in sops.yaml)
# add user(s) hashed password to secrets.yaml
# add user(s) password to pass repo
# tailscale auth key - generate new key in console, add to secrets.yaml - key non-reusable, 90-day expiration, pre-authorized, non-ephemeral, add new tailscale IP in configVars
# update deploy script
# update wallpaper git rev and hash and save locally on deployment host
## MANUAL SETUP POST- FRESH INSTALL ##
# firefox setup (activate extensions, etc.)

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

    hostSpecificConfigs = {
      bootLoader = "systemd-boot";
      storageDrive1 = null;
    };

    networking.hostName = "alder";

    sops.secrets = {
      ericPasswd.neededForUsers = true;
    };

    users.users = { # host specific users, common users defined in nixos-system/admin-users.nix
    
      eric = {
        isNormalUser = true;
        uid = configVars.users.eric.uid;
        hashedPasswordFile = config.sops.secrets.ericPasswd.path;
        extraGroups = [ "wheel" ] 
          ++ lib.optional config.hardware.i2c.enable "i2c"
          ++ lib.optional config.virtualisation.docker.enable "docker";
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = [ 
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDesi3Wba5w6/ZV0kgO4hCcG+n7cDwMuSGca/pCqW4zNlCA95Yd9enkQIAtJfUuXbMjZI7DPezcCptDMySUIBU+Lc3WKScJUsaAUjQCSAEv8E1mq6/qg2p2/0GSyl9NONE1iMlASiq8M/q04CL9E7SD6XJCKtqdAOP4mPi5+xzUJ85tvBlyeF8fTsDGQeUSkMm/N31zuymx9lIgf7KQ7bbV0L5Z5R7cSoGs2NrZDnhMpqFYVCh4LA/hhHg7ed8DE96xSJ6GUnulGVa1C8kCVa/fbU1tNBXfOBCooh7yL1MDGAyseAQC4g2ThwWR9Fpyy23Mn9hrr6tuoZ9lwji5RpthuHOYFey82kaDa50yop2BWwN3yXDZjnWJB6Eo8VrGql9o/WytjRh7YvMCC30jAEHEH8IVYGIT14zO9bC5CCCoP6wonkGjhlhdYJFKPQPKZ6X+bESXaC6+3FXY7CsiI/mWxjc5fdJVQRXZDrZaPwhvt292aSZCTY0sDcFwn8HeOO8= openpgp:0xE5DCB627"
        ];
      };

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
    system.stateVersion = "25.05";

  };

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "hosts/alder/disk-config-btrfs-luks.nix"
      "hosts/alder/hardware-configuration.nix"
      "nixos-system/host-config-options.nix"
      "nixos-system/boot.nix"
      "nixos-system/networking.nix"
      "nixos-system/tailscale.nix"
      "nixos-system/admin-users.nix"
      "nixos-system/sshd.nix"
      "nixos-system/audio.nix"
      "nixos-system/zsh.nix"
      "nixos-system/fonts.nix"
      #"nixos-system/printing.nix"
      "nixos-system/misc.nix"
      "nixos-system/nixpkgs.nix"
      #"nixos-system/backups.nix"
      "nixos-system/sops.nix"
      "nixos-system/bluetooth.nix"
      "nixos-system/monitoring-client.nix"
      
      "nixos-system/greetd.nix"
      "nixos-system/plasma.nix"
    ])
  ];

}