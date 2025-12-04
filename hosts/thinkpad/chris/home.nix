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
      "home-manager/shared/sops.nix"
      "home-manager/shared/starship.nix"
      "home-manager/shared/neovim.nix"
      "home-manager/shared/pass.nix"
      "home-manager/shared/zsh.nix"

      "home-manager/${username}/git.nix"
      "home-manager/${username}/gnupg.nix"
      "home-manager/${username}/ssh.nix"
      "home-manager/${username}/zsh.nix"
      "home-manager/${username}/hyprland.nix"
    ])
  ];

  home.packages = with pkgs; [
    (import (configLib.relativeToRoot "scripts/get-pass-repo.nix") { inherit pkgs config; })
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
    createDirectories = false;
    download = "${config.home.homeDirectory}/downloads";
    documents = "${config.home.homeDirectory}/documents";
    desktop = null;
  };

  # ensure nextcloud-client directory exists
  systemd.user.tmpfiles.rules = [
    "d %h/nextcloud-client 0755 - - -"
  ];

# start/re-start services after system rebuild
  systemd.user.startServices = "sd-switch";

# original home state version - defines the first version of home-manager installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  home.stateVersion = "25.05";

}
