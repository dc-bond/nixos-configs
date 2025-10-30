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
      "home-manager/chris/zsh.nix"
      "home-manager/chris/starship.nix"
      "home-manager/chris/neovim.nix"
      "home-manager/chris/ssh.nix"
      "home-manager/chris/git.nix"
      "home-manager/chris/gnupg.nix"
      "home-manager/chris/pass.nix"
      
      #"home-manager/chris/email.nix"

      "home-manager/chris/plasma.nix"
      #"home-manager/chris/hyprland.nix"
    ])
  ];

  home.packages = with pkgs; [
    (import (configLib.relativeToRoot "scripts/get-pass-repo.nix") { inherit pkgs config; })
  ];

  programs.home-manager.enable = true; # enable home manager

# define username and home directory
  home = {
    username = configVars.chrisUsername;
    homeDirectory = "/home/${configVars.chrisUsername}";
  };

# define default folders in home directory
  xdg.userDirs = {
    enable = true;
    createDirectories = false;
    download = "${config.home.homeDirectory}/downloads";
    documents = "${config.home.homeDirectory}/documents";
    desktop = null;
  };

  # ensure nextcloud-client directory exists
  systemd.user.tmpfiles.rules = [
    "d %h/nextcloud-client 0755 - - -"
    "d %h/test 0755 - - -"
  ];

# start/re-start services after system rebuild
  systemd.user.startServices = "sd-switch";

# original home state version - defines the first version of home-manager installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  home.stateVersion = "25.05";

}
