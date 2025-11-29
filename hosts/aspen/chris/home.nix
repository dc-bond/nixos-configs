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
      "home-manager/shared/starship.nix"
      "home-manager/shared/neovim.nix"
      "home-manager/shared/zsh.nix"

      "home-manager/${username}/zsh.nix"
    ])
  ];

  programs.home-manager.enable = true; # enable home manager

# define username and home directory
  home = {
    username = username;
    homeDirectory = "/home/${username}";
  };

# define default folders in home directory
  xdg.userDirs = {
    enable = true;
    download = "${config.home.homeDirectory}/downloads";
    desktop = null;
  };

# start/re-start services after system rebuild
  systemd.user.startServices = "sd-switch";

# original home state version - defines the first version of home-manager installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  home.stateVersion = "24.11";

}
