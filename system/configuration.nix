{ inputs, outputs, lib, config, pkgs, ... }: 

# module imports
{
  imports = [
    ./hardware-configuration.nix
    #./system-modules/hyprland.nix
    ./system-modules/gnupg.nix
    ./system-modules/yubikey.nix
    #inputs.sops-nix.nixosModules.sops # import sops module
    inputs.home-manager.nixosModules.home-manager # import home-manager module declared in flake.nix
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
  environment.systemPackages = with pkgs; [ # search system packages with 'nix search [package]'
    usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
  ];

# nix package manager related
  nix = 
  let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    channel.enable = false;
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    settings = {
      experimental-features = "nix-command flakes";
      flake-registry = "";
      nix-path = config.nix.nixPath; # workaround for https://github.com/NixOS/nix/issues/9574
    };
  };

# settings for home-manager module
  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      chris = import ../home-manager/home.nix;
    };
  };

# boot configs
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernel.sysctl = { "vm.swappiness" = 30;};
  };

# set hostname
  networking.hostName = "thinkpad";

# wifi
# https://git.kernel.org/pub/scm/network/wireless/iwd.git/tree/src/iwd.network.rst
  networking.wireless.iwd = { 
    enable = true;
    settings = {
      IPv6 = {
      Enabled = false;
      };
      Settings = {
        AutoConnect = true;
      };
    };
  };

# bluetooth
  services.blueman.enable = true; # terminal-based bluetooth connection tool
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

# firewall
  networking.nftables.enable = true; # use nftables for the firewall instead of default iptables
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 
      # 28764 # not needed as openssh server if active automatically opens port(s)
    ];
  };

## nix-index - file database search functionality for nixos, provides 'nix-locate' tool
#  programs.nix-index = {
#    enable = true;
#    enableZshIntegration = true;
#  };

# enable fonts 
  fonts.fontDir.enable = true;

# sops
#sops.defaultSopsFile = ./secrets/secrets.sops.yaml;
#sops.defaultSopsFormat = "yaml";

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
  
# original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "23.11";

}
