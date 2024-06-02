{
  description = "thinkpad laptop system configuration flake";

  inputs = {
    nixpkgs = {
      #url = "github:NixOS/nixpkgs/nixos-23.11"; 
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    home-manager = {
      #url = "github:nix-community/home-manager/release-23.11";
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #hyprland.url = "github:hyprwm/Hyprland";
    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    };
  };

  outputs = { self, nixpkgs, home-manager, hyprland, ... } @ inputs:
  let
    inherit (self) outputs;
  in {
    nixosConfigurations = {
      thinkpad = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs outputs; };
        modules = [
          ./system/configuration.nix
          hyprland.nixosModules.default
          { 
            programs.hyprland = {
              enable = true;
              xwayland.enable = true;
            };
          }
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