{ 
  inputs, 
  config, 
  pkgs, 
  ... 
}: 

{
  
  imports = [
    ./modules/gnupg.nix
    ./modules/neovim.nix
    ./modules/shell.nix
    ./modules/hyprland.nix
    ./modules/alacritty.nix
    ./modules/gammastep.nix
    ./modules/vscodium.nix
    ./modules/firefox.nix
    ./modules/theme.nix
    ./modules/rofi.nix
    ./modules/waybar.nix
    ./modules/wlogout.nix
  ];

# home-manager module settings
  programs.home-manager.enable = true;

# define username and home directory
  home = {
    username = "chris";
    homeDirectory = "/home/chris";
  };

# define default folders in home directory
  xdg.userDirs = {
    enable = true;
    download = "${config.home.homeDirectory}/downloads";
    desktop = null;
  };

# user-specific packages
  home.packages = with pkgs; [
    eza # modern replacement for 'ls'
    pfetch # system info displayed on shell startup
    btop # system monitor
    nmap # network scanning
    swww # animated wallpaper for wayland window managers
    pywal # color theme changer
    dunst # notification daemon
    gnome.gnome-calculator # calculator
    loupe # image viewer
    zathura # barebones pdf viewer
    #whitesur-cursors # macos cursor theme
    nextcloud-client # nextcloud local syncronization client
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
        #identityFile = "~/.ssh/chris-ed25519.key";
        #identityFile = "~/.ssh/chris-gpgauth-yubikey321.pub";
      };
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

# start/re-start services after system rebuild
  systemd.user.startServices = "sd-switch";

# original home state version - defines the first version of home-manager installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  home.stateVersion = "23.11";

}
