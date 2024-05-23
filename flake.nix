{
  description = "thinkpad laptop system configuration flake";

  inputs = {
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11"; # stable repo
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # for cutting-edge repo
    #home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs"; # home-manager sources nixpkgs for its own use so make home-manager use the same version of nixpkgs defined above to avoid getting out of sync
    #sops-nix.url = "github:Mic92/sops-nix";
    #sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs:
  let
    lib = nixpkgs.lib; # specify nixpkgs version of lib
    inherit (self) outputs;
  in {
    nixosConfigurations = { # output set that contains details on one or more system configurations
      thinkpad = lib.nixosSystem { # specify 'thinkpad' as system configuration name
        specialArgs = {inherit inputs outputs;}; # thinkpad system configuration inherits the inputs and outputs of this flake
        modules = [
          ./system/configuration.nix # nixos system configuration module is in effect the configuration.nix file
        ];
      };
    };
  };
}