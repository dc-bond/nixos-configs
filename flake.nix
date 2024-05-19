{
  description = "thinkpad laptop flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11"; # update to new channel identifier to update?
    #sops-nix.url = "github:Mic92/sops-nix";
    #sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs"; # use version of nixpkgs defined above instead of home-manager's default to avoid getting out of sync
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    inherit (self) outputs;
  in {
    nixosConfigurations = {
      thinkpad = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./system/configuration.nix
        ];
      };
    };
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
