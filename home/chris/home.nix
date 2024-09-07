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
    #inputs.plasma-manager.homeManagerModules.plasma-manager
    #./modules/plasma.nix
    ./modules/alacritty.nix
    ./modules/gammastep.nix
    ./modules/vscodium.nix
    ./modules/firefox.nix
    ./modules/theme.nix
    ./modules/rofi.nix
    ./modules/waybar.nix
    #./modules/swaylock.nix
    #./modules/wlogout.nix
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
    (import ../../scripts/desktopReload.nix { inherit pkgs config; }) # for hyprland
    eza # modern replacement for 'ls'
    pfetch # system info displayed on shell startup
    btop # system monitor
    nmap # network scanning
    swww # animated wallpaper for wayland window managers
    pywal # color theme changer
    dunst # notification daemon
    #polkit-kde-agent # kde gui authentication agent
    #libnotify # library to support notification daemons
    #xfce.xfce4-power-manager # laptop power manager - broken?
    #grim # wayland screenshot tool
    #slurp # wayland region selector
    #scrot # screenshot tool
    xfce.thunar # file manager
    gnome.gnome-calculator # calculator
    #filelight # disk usage visualizer
    zathura # barebones pdf viewer
    ##ffmpegthumbnailer
    #wlr-randr # wayland display setting tool for external monitors
    #autorandr # automatically select a display configuration based on connected devices
    #wl-clipboard # wayland clipboard
    #cliphist # wayland clipboard manager 
    #wl-clip-persist # persist clipboard history after closing window
    #pwvucontrol # pipewire audio volume control app
    whitesur-cursors # macos cursor theme
    nextcloud-client # nextcloud local syncronization client
    # fonts - 
    source-code-pro
    source-sans-pro
    font-awesome
    (pkgs.nerdfonts.override { # override installing the entire nerdfonts repo and only install specified fonts from the nerdfonts repo
      fonts = [
        "SourceCodePro"
        "DroidSansMono"
      ];
    })
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

# start/re-start services after system rebuild
  systemd.user.startServices = "sd-switch";

# original home state version - defines the first version of home-manager installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  home.stateVersion = "23.11";

}
