{
  description = "thinkpad laptop system configuration flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # for cutting-edge repo
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # home-manager sources nixpkgs for its own use so make home-manager use the same version of nixpkgs defined above to avoid getting out of sync
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    nixosConfigurations = {
      thinkpad = lib.nixosSystem {
        inherit system;
        modules = [
          ./system/configuration.nix
        ];
      };
    };
    homeConfigurations = {
      chris = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home/chris/home.nix 
        ];
      };
    };
  };
}