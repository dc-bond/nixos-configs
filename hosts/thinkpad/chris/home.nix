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
      "home-manager/common/gnupg.nix"
      "home-manager/common/zsh.nix"
      "home-manager/common/pass.nix"
      "home-manager/common/starship.nix"
      "home-manager/common/email.nix"
      
      "home-manager/common/alacritty.nix"
      "home-manager/common/gammastep.nix"
      "home-manager/common/vscodium.nix"
      "home-manager/common/firefox.nix"
      "home-manager/common/theme.nix"
      "home-manager/common/rofi.nix"
      "home-manager/common/git.nix"
      "home-manager/common/wlogout.nix"
      
      "home-manager/host-specific/thinkpad/chris/aliases.nix"
      "home-manager/host-specific/thinkpad/chris/ssh.nix"

      "home-manager/host-specific/thinkpad/chris/hyprland.nix"
      "home-manager/host-specific/thinkpad/chris/waybar.nix"
    ])
  ];

# home-manager module settings
  programs.home-manager.enable = true;

# define username and home directory
  home = {
    username = configVars.userName;
    homeDirectory = "/home/${configVars.userName}";
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
  home.stateVersion = "23.11";

}
