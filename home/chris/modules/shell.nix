{ config, lib, pkgs, ... }: 

{

  programs.zsh = {
    enable = true;
    autocd = true; # move to directory without using cd
    #initExtra = # added to zsh interactive shell (.zshrc)
    ''
      pfetch
    '';
    shellAliases = {
      ls = "eza -all --long -g -h --color=always --group-directories-first --git";
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-configs";
      update = "sudo nix flake update ~/nixos-configs";
      overhaul = "sudo nix flake update ~/nixos-configs && sudo nixos-rebuild switch --flake ~/nixos-configs";
      wgup = "sudo networkctl up wg0";
      wgdn = "sudo networkctl down wg0";
      wglogon = "echo module wireguard +p | sudo tee /sys/kernel/debug/dynamic_debug/control";
      wglogs = "journalctl -ekf";
      networks = "iwctl station wlan0 get-networks";
    };
    zplug = {
      enable = true;
      plugins = [
        { name = "zsh-users/zsh-autosuggestions"; } # shadow text suggested completions ahead of typing
        { name = "marlonrichert/zsh-autocomplete"; } # show list of possible completions as typing
      ];
    };
    history.size = 5000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };

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