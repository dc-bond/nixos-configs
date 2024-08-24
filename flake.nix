{
  description = "thinkpad laptop system configuration flake";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-24.05";
    };
    #nixpkgs-unstable = {
    #  url = "github:NixOS/nixpkgs/nixos-unstable";
    #};
    home-manager = {
      #url = "github:nix-community/home-manager";
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #hyprland = {
    #  url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    #};
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { 
    self, 
    nixpkgs, 
    #nixpkgs-unstable, 
    #hyprland,
    home-manager, 
    sops-nix, 
    ... 
    } @ inputs:
  let
    inherit (self) outputs;
  in {
    nixosConfigurations = {
      thinkpad = nixpkgs.lib.nixosSystem {
        specialArgs = { 
          inherit inputs outputs;
        };
        modules = [
          ./system/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.chris = import ./home/chris/home.nix;
              extraSpecialArgs = { inherit inputs outputs; };
            };
          }
        ];
      };
    };
  };
}
