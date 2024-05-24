{
  description = "thinkpad laptop system configuration flake";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-23.11"; 
      #url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    home-manager = {
      #url = "github:nix-community/home-manager/release-23.11";
      #url = "github:nix-community/home-manager/master";
      url = "github:nix-community/home-manager"; # is there a reason to specify release channel 23.11 if I also have the 'follows = nixpkgs' line below?
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs: # can someone explain what the '@ inputs' bit does and why I would need or want it?
  let
    #system = "x86_64-linux"; # why does my setup work WITHOUT this line (i.e. its commented out)?
    #pkgs = import nixpkgs {inherit system;}; # why does my setup work WITHOUT this line (i.e. commented out)?
    #lib = nixpkgs.lib; 
    inherit (self) outputs; # can someone explain what this line does and why I would need or want it?
  in {
    nixosConfigurations = {
      thinkpad = nixpkgs.lib.nixosSystem { # is this preferred like this, or should this be abstracted out by just putting 'lib.nixosSystem' and declaring 'lib = nixpkgs.lib' in the let binding above?
        specialArgs = {inherit inputs outputs;}; # can someone explain what this line does exactly and why I would need it?
        modules = [
          ./system/configuration.nix
        ];
      };
    };
  };
}