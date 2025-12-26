{ 
  inputs, 
  config,
  lib,
  configLib,
  configVars,
  pkgs, 
  ... 
}: 

let
  username = builtins.baseNameOf ./.;
in

{
  
  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "home-manager/shared/neovim.nix"
      "home-manager/shared/starship.nix"
      "home-manager/shared/zsh.nix"
    ])
  ];

# home-manager module settings
  programs.home-manager.enable = true;

# define username and home directory
  home = {
    username = username;
    homeDirectory = "/${username}";
  };

# original home state version - defines the first version of home-manager installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  home.stateVersion = "25.05";

}
