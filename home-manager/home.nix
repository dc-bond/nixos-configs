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
  ];

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
      vim = "nvim";

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

# outgoing ssh
  #services.ssh-agent.enable = true; # default is false, comment out if using gpg-agent to serve ssh
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "opticon" = {
        hostname = "opticon";
        user = "xixor";
        port = 39800;
        identityFile = "~/.ssh/chris@dcbond.com-ssh.key";
      };
      "github" = {
        hostname = "github.com";
        user = "dc-bond";
        port = 22;
        identityFile = "~/.ssh/chris@dcbond.com-ssh.key";
      };
    };
  };

 # gnupg 
  programs.gpg = {
    enable = true;
    homedir = "${config.home.homeDirectory}/.gnupg";
    publicKeys = [ # to-do add public key declaratively
      {source = ../chris@dcbond.com-gpg.pub; trust = 5;}
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
      default-key = "A8DD4B51A93E2D9C15B4D27F0419FDA34202A683";
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
    #enableZshIntegration = true;
    #pinentryFlavor = "pinentry-rofi";
    #pinentryFlavor = "pinentry-curses";
    enableScDaemon = true;
  };

# git
  programs.git = {
    enable = true;
    userName  = "dc-bond";
    userEmail = "chris@dcbond.com";
  };

# start/re-start services after system rebuild
  systemd.user.startServices = "sd-switch";

# ?
  home.stateVersion = "23.11";
}
