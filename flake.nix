{

  description = "Chris' NixOS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-2505.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
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
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    finplanner = {
      url = "github:dc-bond/finplanner";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    private.url = "git+file:../nixos-configs-private?ref=main";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: # the @inputs makes all input modules available for the rest of the configuration, but still need nixpkgs, home-manager, etc. because referencing those in the flake here itself below for mkHost function

  let

    inherit (nixpkgs) lib;
    configVars = import ./vars { inherit inputs lib; };
    configLib = import ./lib { inherit lib; };
    mkHost = hostname:
      let
        hostConfig = configVars.hosts.${hostname};
        specialArgs = {
          inherit inputs configVars configLib;
          nixpkgs = nixpkgs;
          outputs = self;
        };
      in
      nixpkgs.lib.nixosSystem {
        system = hostConfig.system;
        inherit specialArgs;
        modules = [
          ./hosts/${hostname}/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users = lib.genAttrs
                (hostConfig.users ++ ["root"]) # always include root user in hosts
                (user: import ./hosts/${hostname}/${user}/home.nix); # include users defined in each host in configVars
              extraSpecialArgs = specialArgs; # passes flake inputs and outputs to home-manager module
            };
          }
        ];
      };

  in 
  
  {
    inherit configVars;
    overlays = import ./overlays {inherit inputs;}; # custom packages and mods exported as overlays
    nixosConfigurations = lib.mapAttrs (hostname: _: mkHost hostname) configVars.hosts; # auto-generate all hosts defined in configVars
  };

}