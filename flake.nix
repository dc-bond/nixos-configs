{
  description = "thinkpad laptop system configuration flake";

  inputs = {
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # for cutting-edge repo
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11"; # stable repo
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # home-manager sources nixpkgs for its own use so make home-manager use the same version of nixpkgs defined above to avoid getting out of sync
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    pkgs = import nixpkgs { inherit system; };
  in {
    nixosConfigurations = {
      thinkpad = lib.nixosSystem {
        inherit system;
        modules = [
          ./system/configuration.nix
        ];
      };
    };
  };
}