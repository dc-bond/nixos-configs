{

  description = "Chris' NixOS Flake";

  inputs = {
    # TODO: uncomment when all hosts migrated to 25.11
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    #nixpkgs-2605.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-2511.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-traefik-pinned.url = "github:nixos/nixpkgs/2b0d2b456e4e8452cf1c16d00118d145f31160f9"; # traefik 3.3.6 from 25.05
    nixpkgs-docker-pinned.url = "github:nixos/nixpkgs/2b0d2b456e4e8452cf1c16d00118d145f31160f9"; # docker 27.5.1 from 25.05
    # TODO: uncomment when all hosts migrated to 25.11
    #home-manager = {
    #  url = "github:nix-community/home-manager/release-25.11";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
    #home-manager-2605 = {
    #  url = "github:nix-community/home-manager/release-26.05";
    #  inputs.nixpkgs.follows = "nixpkgs-2605";
    #};
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-2511 = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-2511";
    };
    #plasma-manager = {
    #  #url = "github:nix-community/plasma-manager";
    #  url = "github:nix-community/plasma-manager/6a7d78cebd9a0f84a508bec9bc47ac504c5f51f4";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #  inputs.home-manager.follows = "home-manager";
    #};
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
    # TODO: uncomment when all hosts migrated to 25.11
    #simple-nixos-mailserver = {
    #  url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.11";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    finplanner = {
      url = "github:dc-bond/finplanner";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    private.url = "git+file:../nixos-configs-private?ref=main";
  };

  outputs = {
    self,
    # TODO: uncomment when all hosts migrated to 25.11
    #nixpkgs,
    #nixpkgs-2605,
    #home-manager,
    #home-manager-2605,
    nixpkgs,
    nixpkgs-2511,
    home-manager,
    home-manager-2511,
    ...
  } @ inputs: # the @inputs makes all input modules available for the rest of the configuration, but still need nixpkgs, home-manager, etc. because referencing those in the flake here itself below for mkHost function

  let

    inherit (nixpkgs) lib;
    configVars = import ./vars { inherit inputs lib; };
    configLib = import ./lib { inherit lib; };
    mkHost = hostname:
      let
        hostConfig = configVars.hosts.${hostname};
        # select nixpkgs and home-manager based on host configuration
        # defaults to nixpkgs.url in inputs above if nixpkgsVersion not specified in configVars
        # TODO: uncomment when all hosts migrated to 25.11
        #nixpkgsVersion = hostConfig.nixpkgsVersion or "25.11";
        #selectedNixpkgs = if nixpkgsVersion == "26.05"
        #                  then nixpkgs-2605
        #                  else nixpkgs;
        #selectedHomeManager = if nixpkgsVersion == "26.05"
        #                      then home-manager-2605
        #                      else home-manager;
        nixpkgsVersion = hostConfig.nixpkgsVersion or "25.05";
        selectedNixpkgs = if nixpkgsVersion == "25.11"
                          then nixpkgs-2511
                          else nixpkgs;
        selectedHomeManager = if nixpkgsVersion == "25.11"
                              then home-manager-2511
                              else home-manager;
        specialArgs = {
          inherit inputs configVars configLib;
          nixpkgs = selectedNixpkgs;
          outputs = self;
        };
      in
      selectedNixpkgs.lib.nixosSystem {
        system = hostConfig.system;
        inherit specialArgs;
        modules = [
          ./hosts/${hostname}/configuration.nix
          selectedHomeManager.nixosModules.home-manager
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