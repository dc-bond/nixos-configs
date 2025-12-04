{ 
  config, 
  lib, 
  pkgs, 
  ... 
}: 

{

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
        format = "[$user]($style)@";
        disabled = false;
        show_always = true;
      };
      hostname = {
        disabled = false;
        ssh_only = false;
        format = "[$hostname]($style): ";
        style = "bold bright-purple";
      };
      localip = {
        disabled = false;
        ssh_only = true;
        format = "[$localipv4]($style) ";
        style = "bright-yellow";
      };
      nix_shell = {
        symbol = " ";
        style = "bold bright-purple";
      };
      docker_context = {
        symbol = " ";
        style = "bold blue";
      };
      python = {
        symbol = " ";
        style = "bold green";
        pyenv_version_name = false;
        python_binary = "python3";
      };
      directory = {
        truncation_length = 10;
        truncate_to_repo = false;
        format = "[$path]($style)[$lock_symbol]($lock_style) ";
      };
      cmd_duration = {
        format = "took [$duration]($style) ";
        style = "dimmed green";
        min_time = 10000;  # show command duration over 10,000 milliseconds (10 sec)
      };
      character = {
        success_symbol = "[➜](bold green) ";
        error_symbol = "[✖](bold red) ";
      };
    };
  };

}