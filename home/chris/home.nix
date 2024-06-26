{ inputs, config, pkgs, ... }: 

{
  
# module imports
  imports = [
    #home-manager.nixosModules.home-manager # imported from flake input
    ./modules/gnupg.nix
    ./modules/neovim.nix
    ./modules/shell.nix
    ./modules/theme.nix
    ./modules/hyprland.nix
  ];

## allow configuration options for packages from the nixpkgs repo
#  nixpkgs = {
#    overlays = [ # override default packages in nixpkgs repo, e.g. older versions, custom patched, etc.
#    ];
#    config = {
#      allowUnfree = true; # allow packages marked as proprietary/unfree
#      allowBroken = false; # do not allow packages marked as broken
#      allowUnfreePredicate = _: true; # workaround for https://github.com/nix-community/home-manager/issues/2942
#    };
#  };

# home-manager module settings
  programs.home-manager.enable = true;

# enable user fonts
  fonts.fontconfig.enable = true;

# define username and home directory
  home = {
    username = "chris";
    homeDirectory = "/home/chris";
  };

# user-specific packages
  home.packages = with pkgs; [
    eza # modern replacement for 'ls'
    pfetch # system info displayed on shell startup
    htop # system monitor
    glances # another system monitor
    nmap # network scanning
  ];

# pass
  programs.password-store = {
    enable = true;
    settings = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.password-store";
    };
  };

# outgoing ssh
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "opticon" = {
        hostname = "vpn.opticon.dev";
        user = "xixor";
        port = 39800;
      };
      "github" = {
        hostname = "github.com";
        user = "dc-bond";
        port = 22;
      };
    };
  };

# git
  programs.git = {
    enable = true;
    userName  = "dc-bond";
    userEmail = "chris@dcbond.com";
  };

# symlink non-module package dotfiles
  home.file = {
    #".sops.yaml".source = ./dotfiles/sops/.sops.yaml;
  };

# start/re-start services after system rebuild
  systemd.user.startServices = "sd-switch";

# original home state version - defines the first version of home-manager installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  home.stateVersion = "23.11";

}