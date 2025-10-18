{ 
  inputs,
  outputs, 
  lib,
  pkgs, 
  config, 
  ... 
}: 

{

  nixpkgs = {
    overlays = [
      outputs.overlays.unstable-packages # import nixpkgs-unstable overlay
    ];
    config = {
      allowUnfree = true; # allow packages marked as proprietary/unfree
      allowBroken = true; # do not allow packages marked as broken
    };
  };

  nix = 
  let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
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

}