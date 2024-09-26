{ 
  inputs, 
  config, 
  pkgs, 
  ... 
}: 

{
  
  imports = [
    ../../common/gnupg.nix
    ../../common/neovim.nix
    ../../common/shell.nix
    ../../common/hyprland.nix
    ../../common/alacritty.nix
    ../../common/gammastep.nix
    ../../common/vscodium.nix
    ../../common/firefox.nix
    ../../common/theme.nix
    ../../common/rofi.nix
    ../../common/waybar.nix
    ../../common/pass.nix
    ../../common/git.nix
    ../../common/ssh.nix
    ../../common/wlogout.nix
    ./aliases.nix
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
