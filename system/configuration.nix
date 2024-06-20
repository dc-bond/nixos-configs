{ inputs, outputs, lib, config, pkgs, ... }: 

{
  
# module imports
  imports = [
    ./hardware-configuration.nix
    ./modules/yubikey.nix
    ./modules/networking.nix
    ./modules/sops.nix
  ];

# allow configuration options for packages from the nixpkgs repo
  nixpkgs = {
    overlays = [ # override default packages in nixpkgs repo, e.g. older versions, custom patched, etc.
    ];
    config = {
      allowUnfree = true; # allow packages marked as proprietary/unfree
      allowBroken = false; # do not allow packages marked as broken
    };
  };

# system-wide packages installed (that aren't installed via their own program modules enabled below)
  environment.systemPackages = with pkgs; [
    #cargo # rust language toolchain
    age # encryption tool
    sops # secrets management tool that can use different types of encryption (e.g. age, pgp, etc.)
    brightnessctl # screen brightness application
    usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
  ];

# nix package manager related
  nix = 
  let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = "nix-command flakes";
      flake-registry = "";
      nix-path = config.nix.nixPath; # workaround for https://github.com/NixOS/nix/issues/9574
      # cachix for hyprland?
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };
    channel.enable = false; # disable channels because using flake
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs; # make flake registry match flake inputs
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs; # make nix path match flake inputs
    gc = { # on a weekly basis, delete any generations older than 7 days then garbage-collect unreferenced programs and symlinks
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

# boot configs
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10; # only display last 10 generations
      };
      efi.canTouchEfiVariables = true;
    };
    #initrd.systemd.network.wait-online.anyInterface = true;
    kernel.sysctl = { "vm.swappiness" = 30;};
    #extraModulePackages = [ config.boot.kernelPackages.wireguard ];
  };

## sops
#  sops.secrets."testkey" = {
#    sopsFile = ./secrets.yaml;
#    #group = "systemd-network";
#    #mode = "0640";
#    #restartUnits = [ "systemd-networkd.service" ];
#    };

## hyprland system module
#  programs.hyprland = {
#    enable = true;
#    xwayland.enable = true; # defaults to true
#  };

# bluetooth
  services.blueman.enable = true; # terminal-based bluetooth connection tool
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

# sound
  security.rtkit.enable = true; # RealtimeKit system service, which hands out realtime scheduling priority to user processes on demand
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    #jack.enable = true;
  };

# enable fonts 
  fonts.fontDir.enable = true;

# user setup
  users.users = {
    chris = {
      initialPassword = "changeme";
      extraGroups = ["wheel"];
      isNormalUser = true;
      shell = pkgs.zsh; # user-specific z-shell configs in home.nix
      openssh.authorizedKeys.keys = [ 
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDJZBJOhg+DeRoH1UljG6FniW66qtYVmJNYtreg54WL3 chris@dcbond.com"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDesi3Wba5w6/ZV0kgO4hCcG+n7cDwMuSGca/pCqW4zNlCA95Yd9enkQIAtJfUuXbMjZI7DPezcCptDMySUIBU+Lc3WKScJUsaAUjQCSAEv8E1mq6/qg2p2/0GSyl9NONE1iMlASiq8M/q04CL9E7SD6XJCKtqdAOP4mPi5+xzUJ85tvBlyeF8fTsDGQeUSkMm/N31zuymx9lIgf7KQ7bbV0L5Z5R7cSoGs2NrZDnhMpqFYVCh4LA/hhHg7ed8DE96xSJ6GUnulGVa1C8kCVa/fbU1tNBXfOBCooh7yL1MDGAyseAQC4g2ThwWR9Fpyy23Mn9hrr6tuoZ9lwji5RpthuHOYFey82kaDa50yop2BWwN3yXDZjnWJB6Eo8VrGql9o/WytjRh7YvMCC30jAEHEH8IVYGIT14zO9bC5CCCoP6wonkGjhlhdYJFKPQPKZ6X+bESXaC6+3FXY7CsiI/mWxjc5fdJVQRXZDrZaPwhvt292aSZCTY0sDcFwn8HeOO8= openpgp:0xE5DCB627"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA+A1i8WE8o6dA4mtJo+6qe8BcLl7mYq/zkd0TOx7lGI xixor@termius"
        ];
    };
  };

# incoming ssh server
  services.openssh = {
    enable = true;
    ports = [
      28764
    ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };

# set timezone & locale
  time.timeZone = "America/New_York"; # set timezone
  i18n.defaultLocale = "en_US.UTF-8";

# login/cli terminal settings
  console = {
    font = "Lat2-Terminus16";
    #keyMap = "us";
    useXkbConfig = true; # configure the primary console keymap from the xserver keyboard settings
  };

# z-shell
  programs.zsh = {
    enable = true; # z-shell enabled system-wide to source necessary files for users
  };
  environment.pathsToLink = [ "/share/zsh" ]; # to enable z-shell completion for system packages like systemd

# set systemd file limit
  systemd.extraConfig = "DefaultLimitNOFILE=2048"; # defaults to 1024 if unset

## lid switch functionality for laptop
#  services.logind.lidSwitch = "ignore";
  
# original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "23.11";

}