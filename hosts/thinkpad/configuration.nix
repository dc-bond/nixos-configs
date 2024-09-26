{ 
  inputs, 
  outputs, 
  lib, 
  config, 
  pkgs, 
  ... 
}: 

{
  
  imports = [
    ./hardware-configuration.nix
    ../../nixos-system/common/audio.nix
    ../../nixos-system/common/nixpkgs.nix
    ../../nixos-system/common/fonts.nix
    ../../nixos-system/common/yubikey.nix
    ../../nixos-system/common/login.nix
    ../../nixos-system/common/users.nix
    ../../nixos-system/common/networking.nix
    ../../nixos-system/common/wireguard.nix
    ../../nixos-system/common/keyring.nix
    ../../nixos-system/common/sshd.nix
    ../../nixos-system/common/thunar.nix
    ../../nixos-system/common/hyprland.nix
    ../../nixos-system/common/printing.nix
    ../../nixos-system/host-specific/thinkpad/sops.nix
    ../../nixos-system/host-specific/thinkpad/bluetooth.nix
  ];

# allow configuration options for packages from the nixpkgs repo
  #nixpkgs = {
  #  overlays = [
  #    outputs.overlays.unstable-packages # import nixpkgs-unstable overlay
  #  ];
  #  config = {
  #    allowUnfree = true; # allow packages marked as proprietary/unfree
  #    allowBroken = false; # do not allow packages marked as broken
  #  };
  #};

# system-wide packages installed (that aren't installed via their own program modules enabled below)
  environment.systemPackages = with pkgs; [
    (import ../../scripts/hello-world.nix { inherit pkgs config; })
    (import ../../scripts/rebuild.nix { inherit pkgs config; })
    age # encryption tool
    sops # secrets management tool that can use different types of encryption (e.g. age, pgp, etc.)
    wget # download tool
    brightnessctl # screen brightness application
    usbutils # package that provides 'lsusb' tool to see usb peripherals plugged in
    ddcutil # query and change monitor settings using DDC/CI and USB
    i2c-tools # hardware interface tools required by ddcutil
    nvd # package version diff info for nix build operations
    nix-tree # table view of package dependencies
    ethtool # network tools
    unzip # utility to unzip directories
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
    kernel.sysctl = { "vm.swappiness" = 30;};
    initrd.preLVMCommands = # turn on keyboard num-lock automatically during boot process
    ''
      ${pkgs.kbd}/bin/setleds +num
    '';
  };

# enable i2c kernel module for ddcutil functionality
  hardware.i2c.enable = true;

# set timezone & locale
  time.timeZone = "America/New_York"; # set timezone
  i18n.defaultLocale = "en_US.UTF-8";

# login/cli terminal settings
  console = {
    earlySetup = true;
    font = "Lat2-Terminus16";
    #font = "${pkgs.source-code-pro}/share/consolefonts/???.gz"; # need to fix
    #packages = with pkgs; [ source-code-pro ];
    keyMap = "us";
  };

# z-shell
  programs.zsh = {
    enable = true; # z-shell enabled system-wide to source necessary files for users
  };
  environment.pathsToLink = [ "/share/zsh" ]; # to enable z-shell completion for system packages like systemd

# disable suspend on laptop lid close
  services.logind.lidSwitch = "ignore";

# set systemd file limit
  systemd.extraConfig = "DefaultLimitNOFILE=2048"; # defaults to 1024 if unset

# original system state version - defines the first version of NixOS installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  system.stateVersion = "23.11";

}