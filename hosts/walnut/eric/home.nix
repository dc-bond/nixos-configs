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
      "home-manager/eric/zsh.nix"
      "home-manager/eric/starship.nix"
      "home-manager/eric/neovim.nix"
      "home-manager/eric/plasma.nix"
    ])
  ];

  programs.home-manager.enable = true; # enable home manager

# define username and home directory
  home = {
    username = configVars.ericUsername;
    homeDirectory = "/home/${configVars.ericUsername}";
  };

# define default folders in home directory
  xdg.userDirs = {
    enable = true;
    createDirectories = false;
    download = "${config.home.homeDirectory}/downloads";
    documents = "${config.home.homeDirectory}/documents";
    desktop = null;
  };

  ## ensure nextcloud-client directory exists
  #systemd.user.tmpfiles.rules = [
  #  "d %h/nextcloud-client 0755 - - -"
  #];

# start/re-start services after system rebuild
  systemd.user.startServices = "sd-switch";

# original home state version - defines the first version of home-manager installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  home.stateVersion = "25.05";

}
