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
    ./modules/pass.nix
    ./modules/git.nix
    ./modules/ssh.nix
    #./modules/plasma.nix
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
    nextcloud-client # nextcloud local syncronization client
  ];

# start/re-start services after system rebuild
  systemd.user.startServices = "sd-switch";

# original home state version - defines the first version of home-manager installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  home.stateVersion = "23.11";

}
