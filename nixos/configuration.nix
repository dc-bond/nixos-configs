{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

  nixpkgs = {
      overlays = [
      ];
      config = {
        allowUnfree = false;
      };
    };
  
    nix = let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in {
      settings = {
        experimental-features = "nix-command flakes";
        # disable global registry
        flake-registry = "";
        # workaround for https://github.com/NixOS/nix/issues/9574
        nix-path = config.nix.nixPath;
      };
      # disable channels
      channel.enable = false;
  
      # make flake registry and nix path match flake inputs
      registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

  boot.loader.systemd-boot.enable = true; # use systemd-boot EFI boot loader
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl = { "vm.swappiness" = 30;};

  networking.hostName = "thinkpad"; # define hostname

  time.timeZone = "America/New_York"; # set timezone

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    #keyMap = "us";
    useXkbConfig = true; # use xkb.options in tty.
  };

  users.users.chris = {
    isNormalUser = true;
    initialPassword = "changeme"; # disposable password to allow initial user login, change by running 'passwd' in terminal immediately following first login
    home = "/home/chris";
    extraGroups = [ "wheel" ]; # enable ‘sudo’
    openssh.authorizedKeys.keys = [ 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOOuXAgAXvwd1oKv7tZAR/jdeyXcfj41xb6hrMdP04G7 chris@dcbond.com" 
      ];
  };

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  environment.systemPackages = with pkgs; [ # search system packages with 'nix search [package]'
    wget
    neovim
    git
  ];

  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.openssh.enable = true; # enable openssh service
  services.openssh.ports = [
    28764
  ];
  services.openssh.settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "no";
    KbdInteractiveAuthentication = false;
  };

  services.xserver.libinput.enable = true; # enable touchpad support

  system.copySystemConfiguration = false; # copy configuration.nix from /run/current-system/configuration.nix in case of accidental deletion, not compatible with flakes so disable
  system.stateVersion = "23.11"; # first install nix version pin for maintaining backward compatibility with application data - do not revise

}