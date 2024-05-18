{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: 

# module imports
{
  imports = [
    #./home-modules/yubikey-gpg.nix
  ];

# ?
  nixpkgs = {
    overlays = [
    ];
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

# enable home-manager itself
  programs.home-manager.enable = true;

# fonts

  fonts.fontconfig.enable = true;
  #fonts.packages = with pkgs; [
  #  (pkgs.nerdfonts.override {
  #    fonts = [
  #      "IBMPlexMono"
  #      "SauceCodePro"
  #    ];
  #  })
  #];

# define username and home directory
  home = {
    username = "chris";
    homeDirectory = "/home/chris";
  };

# user-specific packages installed (that aren't installed via their own program modules enabled below)
  home.packages = with pkgs; [ # only for installing packages that don't come with a programs.enable module
    eza # modern replacement for 'ls'
    pfetch # system info displayed on shell startup
    glances # system monitor tool
    sops # encryption tool
    (pkgs.nerdfonts.override {
      fonts = [
        "IBMPlexMono"
        "SauceCodePro"
      ];
    })
  ];

  #programs.alacritty = {
  #  enable = true;
  #  settings = {
  #    font = {
  #      normal = {
  #        family = "IosevkaTerm Nerd Font";
  #        style = "Regular";
  #      };
  #      bold = {
  #        family = "IosevkaTerm Nerd Font";
  #        style = "Bold";
  #      };
  #      italic = {
  #        family = "IosevkaTerm Nerd Font";
  #        style = "Italic";
  #      };
  #      bold_italic = {
  #        family = "IosevkaTerm Nerd Font";
  #        style = "Bold Italic";
  #      };
  #      size = 16;
  #    };
  #  };

# pass
  programs.password-store = {
    enable = true;
    settings = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.password-store";
    };
  };

# z-shell
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    initExtra = ''
      pfetch
    '';
    shellAliases = {
      ls = "eza -all --long -g -h --color=always --group-directories-first --git";
      #vim = "nvim";

      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-configs";
      #flake-update = "nix flake update ~/nixos-configs";
      #upgrade = "sudo nixos-rebuild switch --upgrade --flake ~/nixos-configs#thinkpad";

      configsys = "nvim ~/nixos-configs/system/configuration.nix";
      confighome = "nvim ~/nixos-configs/home-manager/home.nix";

      stageconfig = "cd ~/nixos-configs && git add .";
      pushconfig = "cd ~/nixos-configs && git add . && git commit && git push git@github.com:dc-bond/nixos-configs.git";
      pullconfig = "cd ~/nixos-configs && git pull git@github.com:dc-bond/nixos-configs.git";
    };
    zplug = {
      enable = true;
      plugins = [
        { name = "zsh-users/zsh-autosuggestions"; }
        { name = "marlonrichert/zsh-autocomplete"; }
      ];
    };
    history.size = 5000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };

# starship prompt for shell
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      line_break = {
        disabled = true;
      };
      package = {
        disabled = false;
      };
      username = {
        style_user = "bold yellow";
        style_root = "bold red";
        format = "[$user](style)@";
        disabled = false;
        show_always = true;
      };
      hostname = {
        disabled = false;
        ssh_only = false;
        format = "[$hostname](bold blue): ";
      };
      nix_shell = {
        symbol = " ";
        style = "bold bright-purple";
      };
      docker_context = {
        symbol = " ";
        style = "blue bold";
      };
      python = {
        symbol = " ";
        style = "green bold";
        pyenv_version_name = false;
        python_binary = "python3";
      };
      directory = {
        #read_only = "";
        truncation_length = 10;
        truncate_to_repo = false;
        format = "[$path]($style)[$lock_symbol]($lock_style) ";
      };
      cmd_duration = {
        format = "took [$duration]($style) ";
        min_time = 10000;  # show command duration over 10,000 milliseconds (10 sec)
      };
      character = {
        success_symbol = "[➜](bold green) ";
        error_symbol = "[✖](bold red) ";
      };
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
  #services.ssh-agent.enable = true; # default is false, comment out if using gpg-agent to serve ssh
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

 # gnupg 
  programs.gpg = {
    enable = true;
    homedir = "${config.home.homeDirectory}/.gnupg";
    publicKeys = [ 
      { source = ../DB9ADBBE6FBD1F0E694AF25D012321D46E090E61.pub; trust = 5; }
    ];
    settings = {
      use-agent = true; # to enable smartcard/ssh support?
      no-greeting = true;
      armor = true;
      no-emit-version = true;
      no-comments = true;
      no-symkey-cache = true;
      require-cross-certification = true;
      throw-keyids = true;
      with-fingerprint = true;
      default-key = "DB9ADBBE6FBD1F0E694AF25D012321D46E090E61";
      keyid-format = "0xlong";
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      keyserver = "hkps://keyserver.ubuntu.com";
      personal-cipher-preferences = "AES256 TWOFISH AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256 SHA224";
      cert-digest-algo = "SHA512";
      default-preference-list = "SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed";
    };
    scdaemonSettings = {
      disable-ccid = true;      
    };
  };

# gpg-agent
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableZshIntegration = true;
    #pinentryFlavor = "pinentry-rofi";
    enableScDaemon = true;
  };

# git
  programs.git = {
    enable = true;
    userName  = "dc-bond";
    userEmail = "chris@dcbond.com";
  };

# symlink non-module package dotfiles
  home.file = {
    ".sops.yaml".source = ./home-dotfiles/.sops.yaml;
  };

# start/re-start services after system rebuild
  systemd.user.startServices = "sd-switch";

# ?
  home.stateVersion = "23.11";
}
