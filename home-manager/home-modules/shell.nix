{ config, lib, pkgs, ... }: 

{

# z-shell
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    initExtra = ''
      pfetch
    '';
    shellAliases = {
      ls = "eza -all --long -g -h --color=always --group-directories-first --git";
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-configs";
      flakeupdate = "nix flake update ~/nixos-configs";
      #upgrade = "sudo nixos-rebuild switch --upgrade --flake ~/nixos-configs#thinkpad";
      configsys = "nvim ~/nixos-configs/system/configuration.nix";
      confighome = "nvim ~/nixos-configs/home-manager/home.nix";
      stageconfig = "cd ~/nixos-configs && git add .";
      pushconfig = "cd ~/nixos-configs && git add . && git commit && git push origin main";
      pullconfig = "cd ~/nixos-configs && git pull origin main";
      #pushconfig = "cd ~/nixos-configs && git add . && git commit && git push git@github.com:dc-bond/nixos-configs.git";
      #pullconfig = "cd ~/nixos-configs && git pull git@github.com:dc-bond/nixos-configs.git";
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
# https://starship.rs/config/#prompt
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      command_timeout = 20000;
      scan_timeout = 20000;
      line_break = {
        disabled = true;
      };
      package = {
        disabled = false;
      };
      username = {
        style_user = "bold green";
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

}