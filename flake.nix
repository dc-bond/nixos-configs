{
  description = "thinkpad laptop flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    sops-nix,
    ...
  } @ inputs: let
    inherit (self) outputs;
  in {
    nixosConfigurations = {
      thinkpad = nixpkgs.lib.nixosSystem {
        modules = [
          ./nixos/configuration.nix
          ];
      };
    };
    #homeConfigurations = {
    #  "chris@thinkpad" = home-manager.lib.homeManagerConfiguration {
    #    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    #    extraSpecialArgs = {inherit inputs outputs;};
    #    modules = [./home-manager/home.nix];
    #  };
    #};
  };
}

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