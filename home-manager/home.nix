{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
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

  home.packages = with pkgs; [
    eza # modern replacement for 'ls'
    pfetch # system info displayed on shell startup
    glances # system monitor tool
    #starship # adds prompt customizations to shell
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      ls = "eza -all --long -g -h --color=always --group-directories-first --git";
      vim = "nvim";

      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-configs";
      flake-update = "nix flake update ~/nixos-configs";
      #upgrade = "sudo nixos-rebuild switch --upgrade --flake ~/nixos-configs#thinkpad";

      configsys = "nvim ~/nixos-configs/system/configuration.nix";
      confighome = "nvim ~/nixos-configs/home-manager/home.nix";

      stageconfig = "cd ~/nixos-configs && git add .";
      pushconfig = "cd ~/nixos-configs && git add . && git commit && git push git@github.com:dc-bond/nixos-configs.git";
      pullconfig = "cd ~/nixos-configs && git pull --repo git@github.com:dc-bond/nixos-configs.git";
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

  #programs.starship.enable = true;
  #programs.starship.settings = {
  #  add_newline = false;
  #  format = "$shlvl$shell$username$hostname$nix_shell$git_branch$git_commit$git_state$git_status$directory$jobs$cmd_duration$character";
  #  shlvl = {
  #    disabled = false;
  #    symbol = "ﰬ";
  #    style = "bright-red bold";
  #  };
  #  shell = {
  #    disabled = false;
  #    format = "$indicator";
  #    fish_indicator = "";
  #    bash_indicator = "[BASH](bright-white) ";
  #    zsh_indicator = "[ZSH](bright-white) ";
  #  };
  #  username = {
  #    style_user = "bright-white bold";
  #    style_root = "bright-red bold";
  #  };
  #  hostname = {
  #    style = "bright-green bold";
  #    ssh_only = true;
  #  };
  #  nix_shell = {
  #    symbol = "";
  #    format = "[$symbol$name]($style) ";
  #    style = "bright-purple bold";
  #  };
  #  git_branch = {
  #    only_attached = true;
  #    format = "[$symbol$branch]($style) ";
  #    symbol = "שׂ";
  #    style = "bright-yellow bold";
  #  };
  #  git_commit = {
  #    only_detached = true;
  #    format = "[ﰖ$hash]($style) ";
  #    style = "bright-yellow bold";
  #  };
  #  git_state = {
  #    style = "bright-purple bold";
  #  };
  #  git_status = {
  #    style = "bright-green bold";
  #  };
  #  directory = {
  #    read_only = " ";
  #    truncation_length = 0;
  #  };
  #  cmd_duration = {
  #    format = "[$duration]($style) ";
  #    style = "bright-blue";
  #  };
  #  jobs = {
  #    style = "bright-green bold";
  #  };
  #  character = {
  #    success_symbol = "[\\$](bright-green bold)";
  #    error_symbol = "[\\$](bright-red bold)";
  #  };
  #};

  programs.git = {
    enable = true;
    userName  = "Chris Bond";
    userEmail = "chris@dcbond.com";
  };

  # git remote add nixos-configs https://github.com/dc-bond/nixos-configs.git
  # git remote rm origin
  # git remote set-url nixos-configs git@github.com:dc-bond/nixos-configs.git 

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "23.11";
}
