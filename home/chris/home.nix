{ inputs, config, pkgs, ... }: 

{
  
# module imports
  imports = [
    ./modules/gnupg.nix
    ./modules/shell.nix
    ./modules/hyprland.nix
  ];

# allow configuration options for packages from the nixpkgs repo
  nixpkgs = {
    overlays = [ # override default packages in nixpkgs repo, e.g. older versions, custom patched, etc.
    ];
    config = {
      allowUnfree = true; # allow packages marked as proprietary/unfree
      allowBroken = false; # do not allow packages marked as broken
      allowUnfreePredicate = _: true; # workaround for https://github.com/nix-community/home-manager/issues/2942
    };
  };

# enable home-manager itself
  programs.home-manager.enable = true;

# enable user fonts
  fonts.fontconfig.enable = true;

# define username and home directory
  home = {
    username = "chris";
    homeDirectory = "/home/chris";
  };

# user-specific packages installed (that aren't installed via their own program modules enabled below)
  home.packages = with pkgs; [ # only for installing packages that don't come with a programs.enable module
    eza # modern replacement for 'ls'
    pfetch # system info displayed on shell startup
    glances # system monitor
    sops # encryption
    nmap # network scanning
    (pkgs.nerdfonts.override { # override installing the entire nerdfonts repo and only install specified fonts from the nerdfonts repo
      fonts = [
        "IBMPlexMono" # name is 'BlexMono' for system configs
        "SourceCodePro" # name is 'SauceCodePro' for system configs
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

# neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraConfig = ''
      " set colorscheme
      colorscheme nord

      " general settings
      set path+=**					          " Searches current directory recursively.
      set wildmenu					          " Display all matches when tab complete.
      set incsearch                   " Incremental search
      set hidden                      " Needed to keep multiple buffers open
      set nobackup                    " No auto backups
      set noswapfile                  " No swap
      set t_Co=256                    " Set if term supports 256 colors.
      set number relativenumber       " Display line numbers
      set clipboard=unnamedplus       " Copy/paste between vim and other programs.
      syntax enable
      "let g:rehash256 = 1

      " statusline
      let g:lightline = {
            \ 'colorscheme': 'nord',
            \ }
      
      " always show statusline
      set laststatus=2

      " fix aut-indentation for YAML files
      augroup yaml_fix
          autocmd!
          autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab indentkeys-=0# indentkeys-=<:>
      augroup END

      " mouse scrolling
      set mouse=nicr
      set mouse=a

      " fix sizing bug with alacritty terminal
      autocmd VimEnter * :silent exec "!kill -s SIGWINCH $PPID"
    '';
    plugins = with pkgs.vimPlugins; [
      nord-nvim
      fzf-vim
      lightline-vim
      #comfortable-motion.vim
      #vim-beancount
    ];
  };

# outgoing ssh
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "opticon" = {
        hostname = "opticon";
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
    ".sops.yaml".source = ./dotfiles/.sops.yaml;
  };

# start/re-start services after system rebuild
  systemd.user.startServices = "sd-switch";

# original home state version - defines the first version of home-manager installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  home.stateVersion = "23.11";

}