{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: 

{
  imports = [
    ./home-modules/yubikey-gpg.nix
  ];

  nixpkgs = {
    overlays = [
    ];
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  home = {
    username = "chris";
    homeDirectory = "/home/chris";
  };

  home.packages = with pkgs; [ # only for installing packages that don't come with a programs.enable module
    eza # modern replacement for 'ls'
    pfetch # system info displayed on shell startup
    glances # system monitor tool
  ];

  programs.zsh = {
    #enable = true;
    enableCompletion = true;
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
    initExtra = ''
      pfetch
      # eval "$(starship init zsh)"
    '';
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

  programs.starship.enable = true;
  programs.starship.enableZshIntegration = true;
  programs.starship.settings = {
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

  #services.ssh-agent.enable = true; # default is false, comment out if using yubikey-gpg module  
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

  programs.git = {
    enable = true;
    userName  = "dc-bond";
    userEmail = "chris@dcbond.com";
  };

  # git remote add nixos-configs https://github.com/dc-bond/nixos-configs.git
  # git remote rm origin
  # git remote set-url nixos-configs git@github.com:dc-bond/nixos-configs.git 

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "23.11";
}
