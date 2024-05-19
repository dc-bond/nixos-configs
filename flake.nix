{
  description = "thinkpad laptop flake";

  inputs = { # information about sources/inputs to the flake
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11"; #  for current stable repo
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # for cutting-edge repo
    #sops-nix.url = "github:Mic92/sops-nix";
    #sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs"; # use version of nixpkgs defined above instead of home-manager's default to avoid getting out of sync
  };

  outputs = { # information about what the flake should create with the sources/inputs
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: 
  let
    lib = nixpkgs.lib; # define lib as the nixpkgs version of the implementation library
    inherit (self) outputs;
  in {
    nixosConfigurations = { # output set that contains details on a nixos system configuration
      thinkpad = lib.nixosSystem { # if hostname of system is same as 'thinkpad' defined here, no need to specify #thinkpad with the 'nixos-rebuild switch --flake .' command
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./system/configuration.nix # nixos system configuration module is in effect the configuration.nix file
        ];
      };
    };
  };
}

#{
#  description = "thinkpad laptop flake";
#
#  inputs = {
#    nixpkgs.url = "nixpkgs/nixos-23.11"; # update to new channel identifier to update?
#    #sops-nix.url = "github:Mic92/sops-nix";
#    #sops-nix.inputs.nixpkgs.follows = "nixpkgs";
#    home-manager.url = "github:nix-community/home-manager/release-23.11";
#    home-manager.inputs.nixpkgs.follows = "nixpkgs"; # use version of nixpkgs defined above instead of home-manager's default to avoid getting out of sync
#  };
#
#  outputs = {
#    self,
#    nixpkgs,
#    home-manager,
#    ...
#  } @ inputs: let
#    inherit (self) outputs;
#  in {
#    nixosConfigurations = {
#      thinkpad = nixpkgs.lib.nixosSystem {
#        specialArgs = {inherit inputs outputs;};
#        modules = [
#          ./system/configuration.nix
#        ];
#      };
#    };
#  };
#}

#  outputs = { 
#    self, 
#    nixpkgs, 
#    home-manager, 
#    ... 
#  }:
#    let
#      system = "x86_64-linux";
#      lib = nixpkgs.lib;
#      pkgs = nixpkgs.legacyPackages.${system};
#    in {
#      nixosConfigurations = {
#        thinkpad = lib.nixosSystem {
#          inherit system;
#          modules = [ 
#            ./nixos/configuration.nix 
#          ];
#        };
#      };
#      homeConfigurations = {
#        chris = home-manager.lib.homeManagerConfiguration {
#          inherit pkgs;
#          modules = [ 
#            ./home-manager/home.nix 
#          ];
#        };
#      };
#    };
#}
