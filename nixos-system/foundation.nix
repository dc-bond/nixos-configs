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
    overlays = builtins.attrValues outputs.overlays; # pull in all overlays at overlays/default.nix
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
    registry = lib.mkForce (lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs); # make flake registry match flake inputs
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs; # make nix path match flake inputs
    gc = {
      automatic = true;
      dates = "weekly"; # midnight on mondays
      options = "--delete-older-than 30d"; # clear build cache from nix store older than 30 days
      persistent = true; # ensure runs next time host is booted if it was powered off at midnight on monday
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
  systemd.settings.Manager.DefaultLimitNOFILE = 2048;

  # bulk storage configuration
  options.bulkStorage.path = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
    description = "Path to this host's bulk storage (media, backups, NVR recordings)";
  };
}