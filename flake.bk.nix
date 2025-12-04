{
  description = "Chris' NixOS Configurations Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      #url = "github:nix-community/plasma-manager";
      url = "github:nix-community/plasma-manager/6a7d78cebd9a0f84a508bec9bc47ac504c5f51f4";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { 
    self,
    nixpkgs,
    home-manager,
    #plasma-manager,
    sops-nix,
    disko,
    firefox-addons,
    ... 
    } @ inputs:
  let
    inherit (self) outputs;
    inherit (nixpkgs) lib;
    configVars = import ./vars { inherit inputs lib; };
    configLib = import ./lib { inherit lib; };
    forAllSystems = nixpkgs.lib.genAttrs [
      "x86_64-linux"
      #"i686-linux"
      #"aarch64-linux"
    ];
    specialArgs = {
      inherit
        inputs
        outputs
        configVars
        configLib
        nixpkgs
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
              #sharedModules = [ plasma-manager.homeModules.plasma-manager ];
              users.chris = import ./hosts/thinkpad/chris/home.nix;
              users.root = import ./hosts/thinkpad/root/home.nix;
              extraSpecialArgs = specialArgs; # passes flake inputs and outputs to home-manager module
            };
          }
        ];
      };

      cypress = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        inherit specialArgs;
        modules = [
          ./hosts/cypress/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.chris = import ./hosts/cypress/chris/home.nix;
              users.root = import ./hosts/cypress/root/home.nix;
              extraSpecialArgs = specialArgs;
            };
          }
        ];
      };

      aspen = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        inherit specialArgs;
        modules = [
          ./hosts/aspen/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.chris = import ./hosts/aspen/chris/home.nix;
              users.root = import ./hosts/aspen/root/home.nix;
              extraSpecialArgs = specialArgs;
            };
          }
        ];
      };

      juniper = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        inherit specialArgs;
        modules = [
          ./hosts/juniper/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.chris = import ./hosts/juniper/chris/home.nix;
              users.root = import ./hosts/juniper/root/home.nix;
              extraSpecialArgs = specialArgs;
            };
          }
        ];
      };
      
    };
  };
}
