{ 
  inputs,
  outputs, 
  lib,
  pkgs, 
  config, 
  ... 
}: 

let
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
in 

{

  # nixpkgs configuration
  nixpkgs = {
    overlays = [
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
      allowBroken = true;
    };
  };

  # nix package manager settings
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [ "@wheel" ]; # allow remote builds
      warn-dirty = false;
      flake-registry = "";
      nix-path = config.nix.nixPath; # workaround for https://github.com/NixOS/nix/issues/9574
    };
    channel.enable = false; # disable channels because using flake
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs; # make flake registry match flake inputs
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs; # make nix path match flake inputs
    gc = { # every hour, delete generations then garbage-collect unreferenced programs and symlinks
      automatic = true;
      randomizedDelaySec = "60m";
      options = "--delete-older-than +3"; # keep last three generations
    };
  };

  # system locale and regional settings
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  
  console = {
    earlySetup = true;
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # system-wide resource limits
  systemd.extraConfig = "DefaultLimitNOFILE=2048";
}