{
  description = "thinkpad laptop system configuration flake";

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
    firefox-addons,
    #plasma-manager,
    ... 
    } @ inputs:
  let
    inherit (self) outputs;
    #systems = [
    #  "x86_64-linux"
    #  #"i686-linux"
    #  #"aarch64-linux"
    #];
    #forAllSystems = nixpkgs.lib.genAttrs systems;
    forAllSystems = nixpkgs.lib.genAttrs;
  in {
    #packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    #formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    overlays = import ./overlays {inherit inputs;}; # custom packages and mods exported as overlays
    #nixosModules = import ./modules/nixos;
    #homeManagerModules = import ./modules/home-manager;
    nixosConfigurations = {

      thinkpad = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # alternatively could be in hardware-configuration.nix
        specialArgs = { 
          inherit inputs outputs; # passes flake inputs (e.g. nixpkgs, sops-nix, etc.) and outputs (e.g. overlays?) to modules defined below (e.g. configuration.nix)
        };
        modules = [
          ./system/configuration.nix
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.chris = import ./home/home.nix;
              extraSpecialArgs = { inherit inputs outputs; }; # passes flake inputs and outputs to home-manager modules?
            };
          }
        ];
      };

      vm1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { 
          inherit inputs outputs;
        };
        modules = [
          ./system/configuration.nix
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.chris = import ./home/home.nix;
              extraSpecialArgs = { inherit inputs outputs; }; # passes flake inputs and outputs to home-manager modules?
            };
          }
        ];
      };


      
    };
  };
}
