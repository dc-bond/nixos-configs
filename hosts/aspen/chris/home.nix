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
  
  #imports = lib.flatten [
  #  (map configLib.relativeToRoot [
  #    "home-manager/common/neovim.nix"
  #  ])
  #];

# home-manager module settings
  programs.home-manager.enable = true;

# define username and home directory
  home = {
    username = configVars.userName;
    homeDirectory = "/home/${configVars.userName}";
  };

# define default folders in home directory
  xdg.userDirs = {
    enable = false;
  };

# start/re-start services after system rebuild
  systemd.user.startServices = "sd-switch";

# original home state version - defines the first version of home-manager installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  home.stateVersion = "23.11";

}
