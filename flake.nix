{

  description = "Chris' NixOS Flake";

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
    finplanner = {
      url = "github:dc-bond/finplanner";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    private.url = "git+file:../nixos-configs-private";

  };

  outputs = { 
    self,
    nixpkgs,
    home-manager,
    private,
    ... 
  } @ inputs:

  let
    inherit (nixpkgs) lib;
    configVars = import ./vars { inherit inputs lib; };
    configLib = import ./lib { inherit lib; };
    specialArgs = {
      inherit inputs configVars configLib nixpkgs;
      outputs = self;
    };
    mkHost = hostname: nixpkgs.lib.nixosSystem {
      system = configVars.hosts.${hostname}.system;
      inherit specialArgs;
      modules = [
        ./hosts/${hostname}/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users = lib.genAttrs 
              (configVars.hosts.${hostname}.users ++ ["root"]) # always include root user in hosts
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