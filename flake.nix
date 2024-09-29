{
  description = "Chris' NixOS Configurations Flake";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-24.05";
    };
    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disco = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #plasma-manager = {
    #  url = "github:nix-community/plasma-manager";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #  inputs.home-manager.follows = "home-manager";
    #};
  };

  outputs = { 
    self,
    nixpkgs,
    home-manager,
    sops-nix,
    disco,
    firefox-addons,
    #plasma-manager,
    ... 
    } @ inputs:
  let
    inherit (self) outputs;
    #inherit (nixpkgs) lib;
    #configVars = import ./vars { inherit inputs lib; };
    #configLib = import ./lib { inherit lib; };
    forAllSystems = nixpkgs.lib.genAttrs [
      "x86_64-linux"
      #"i686-linux"
      #"aarch64-linux"
    ];
    specialArgs = {
      inherit
        inputs
        outputs
        #configVars
        #configLib
        #nixpkgs
        ;
    };
  in {
    overlays = import ./overlays {inherit inputs;}; # custom packages and mods exported as overlays
    nixosConfigurations = {

      thinkpad = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # alternatively could be in hardware-configuration.nix?
        inherit specialArgs; # passes flake inputs and outputs to modules defined below
        modules = [
          ./hosts/thinkpad/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.chris = import ./home-manager/host-specific/thinkpad/home.nix;
              extraSpecialArgs = specialArgs; # passes flake inputs and outputs to home-manager module
            };
          }
        ];
      };

      vm1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        inherit specialArgs;
        modules = [
          disko.nixosModules.disko
          ./hosts/vm1/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.chris = import ./home-manager/host-specific/vm1/home.nix;
              extraSpecialArgs = specialArgs;
            };
          }
        ];
      };


      
    };
  };
}
