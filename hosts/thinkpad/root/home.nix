{ 
  inputs, 
  config,
  lib,
  configLib,
  configVars,
  pkgs, 
  ... 
}: 

{
  
  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "home-manager/common/neovim.nix"
      "home-manager/common/shell.nix"
    ])
  ];

  programs.home-manager.enable = true;

  services.ssh-agent.enable = true; # ensure ssh-agent is running

# define username and home directory
  home = {
    username = "root";
    homeDirectory = "/root";
  };

# original home state version - defines the first version of home-manager installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  home.stateVersion = "23.11";

}
