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

      "home-manager/${username}/claude-code.nix"
      "home-manager/${username}/git.nix"
      "home-manager/${username}/pass.nix"
      "home-manager/${username}/gnupg.nix"
      "home-manager/${username}/ssh.nix"
      "home-manager/${username}/zsh.nix"
      "home-manager/${username}/hyprland.nix"
    ])
  ];

  programs.home-manager.enable = true; # enable home manager

# define username and home directory
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    packages = with pkgs; [
      brightnessctl # screen brightness control
    ];
  };

# firefox profile lives at the xdg path, not ~/.mozilla; configPath also rewraps
# the firefox package, so home-manager and the browser cannot disagree. set per
# host rather than in shared/firefox.nix because the profiles on the deprecated
# cypress and alder were never moved
  programs.firefox.configPath = ".config/mozilla/firefox";

# define default folders in home directory
  xdg.userDirs = {
    enable = true;
    setSessionVariables = false; # 26.05 default; user-dirs.dirs is still written, which is what xdg-user-dir and file dialogs read
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
