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
      "home-manager/shared/zsh.nix"

      "home-manager/${username}/git.nix"
      "home-manager/${username}/pass.nix"
      "home-manager/${username}/gnupg.nix"
      "home-manager/${username}/ssh.nix"
      "home-manager/${username}/zsh.nix"
      "home-manager/${username}/hyprland.nix"
      "home-manager/${username}/claude-code.nix"
      "home-manager/${username}/thunderbird.nix"
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
    createDirectories = false;
    download = "${config.home.homeDirectory}/downloads";
    documents = "${config.home.homeDirectory}/documents";
    desktop = null;
  };

# default applications - tmpfs root wipes ~/.config/mimeapps.list each boot, so manage it declaratively
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = "firefox.desktop";
      "x-scheme-handler/mailto" = "thunderbird.desktop";
    };
  };

# start/re-start services after system rebuild
  systemd.user.startServices = "sd-switch";

# original home state version - defines the first version of home-manager installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  home.stateVersion = "25.11";

}
