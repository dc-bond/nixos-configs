{
  inputs,
  outputs, # if using home-manager as module?
  lib,
  config,
  pkgs,
  ...
}: 

# module imports
{
  imports = [
    ./hardware-configuration.nix
    #inputs.sops-nix.nixosModules.sops # import sops module
    inputs.home-manager.nixosModules.home-manager # import home-manager module
  ];

# ?
  nixpkgs = {
    overlays = [
    ];
    config = {
      allowUnfree = true;
    };
  };

# ?
  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = "nix-command flakes";
      flake-registry = "";
      nix-path = config.nix.nixPath;
    };
    channel.enable = false;
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

# bootloader configs
  boot.loader.systemd-boot.enable = true; # use systemd-boot EFI boot loader
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl = { "vm.swappiness" = 30;};

# set hostname
  networking.hostName = "thinkpad";

# enable fonts 
  fonts.fontDir.enable = true;

# system-wide packages installed (that aren't installed via their own program modules enabled below)
  environment.systemPackages = with pkgs; [ # search system packages with 'nix search [package]'
    pcsclite # smartcard reader tool for yubikey functionality
    git # installed system-wide to allow ansible root user to clone repo on first install
    usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
  ];

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
        ];
    };
  };

# ?
  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      chris = import ../home-manager/home.nix;
    };
  };

# incoming ssh server
  services.openssh.enable = true; # enable openssh service
  services.openssh.ports = [
    28764 # change and encrypt
  ];
  services.openssh.settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "no";
    KbdInteractiveAuthentication = false;
  };

# ?
  time.timeZone = "America/New_York"; # set timezone

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    #keyMap = "us";
    useXkbConfig = true; # use xkb.options in tty.
  };

# z-shell
  programs.zsh = {
    enable = true; # z-shell enabled system-wide to source necessary files for users
    # added to zsh login shell to enable gpg-agent to serve ssh (.zprofile)
    loginShellInit = ''
      export GPG_TTY="$(tty)"
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
      gpgconf --launch gpg-agent
    '';
  };
  environment.pathsToLink = [ "/share/zsh" ]; # to enable z-shell completion for system packages like systemd
  
# enable smartcard reader tool for yubikey functionality
  services.pcscd.enable = true;
  
# original system state version
  system.stateVersion = "23.11"; # first install nix version pin for maintaining backward compatibility with application data - do not revise

}
