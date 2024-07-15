{ inputs, config, pkgs, ... }: 

{
  
# module imports
  imports = [
    ./modules/gnupg.nix
    ./modules/neovim.nix
    ./modules/shell.nix
    ./modules/hyprland.nix
  ];

# home-manager module settings
  programs.home-manager.enable = true;

# enable user fonts
  fonts.fontconfig.enable = true;

# define username and home directory
  home = {
    username = "chris";
    homeDirectory = "/home/chris";
  };

# define default folders in home directory
  xdg.userDirs = {
    enable = true;
    download = "${config.home.homeDirectory}/downloads";
  };

# user-specific packages
  home.packages = with pkgs; [
    (import ../../scripts/desktopReload.nix { inherit pkgs config; })
    eza # modern replacement for 'ls'
    pfetch # system info displayed on shell startup
    btop # system monitor
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
      #"*" = {
      #  identityFile = "~/.ssh/github-ed25519-yubikey321.key";
      #};
      "opticon" = {
        hostname = "vpn.opticon.dev";
        user = "xixor";
        port = 39800;
        #identityFile = "~/.ssh/chris-ed25519.key";
        #identityFile = "~/.ssh/chris-gpgauth-yubikey321.pub";
      };
      #"github.com"= { # vscodium looks at ~/.ssh/config file and sees this entry to specify correct ssh private key to use when using its integrated git feature
      #  #identityFile = "~/.ssh/github-ed25519-yubikey321.key";
      #  #identityFile = "~/.ssh/chris-ed25519.key";
      #};
    };
  };

# git
  programs.git = {
    enable = true;
    userName  = "dc-bond";
    userEmail = "chris@dcbond.com";
    extraConfig = {
      init.defaultBranch = "main";
      #commit.gpgsign = true;
      #gpg.format = "ssh";
      #gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      #user.signingkey = "~/.ssh/id_ed25519.pub";
    };
  };

# symlink non-module package dotfiles
  #home.file = {
  #  #".sops.yaml".source = ./dotfiles/sops/.sops.yaml;
  #};

# start/re-start services after system rebuild
  systemd.user.startServices = "sd-switch";

# original home state version - defines the first version of home-manager installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  home.stateVersion = "23.11";

}