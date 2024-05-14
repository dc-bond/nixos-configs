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
    ... 
  }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations = {
        thinkpad = lib.nixosSystem {
          inherit system;
          modules = [ 
            ./nixos/configuration.nix 
          ];
        };
      };
      homeConfigurations = {
        chris = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ 
            ./home-manager/home.nix 
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
#  } @ inputs: let
#    inherit (self) outputs;
#  in {
#    nixosConfigurations = {
#      your-hostname = nixpkgs.lib.nixosSystem {
#        specialArgs = {inherit inputs outputs;};
#        # > Our main nixos configuration file <
#        modules = [./nixos/configuration.nix];
#      };
#    };
#
#    homeConfigurations = {
#      "your-username@your-hostname" = home-manager.lib.homeManagerConfiguration {
#        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
#        extraSpecialArgs = {inherit inputs outputs;};
#        # > Our main home-manager configuration file <
#        modules = [./home-manager/home.nix];
#      };
#    };
#  };
#}