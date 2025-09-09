{ 
  config, 
  lib, 
  pkgs, 
  ... 
}: 

{

  programs.zsh = {
    enable = true;
    syntaxHighlighting = { # highlight valid commands in green and invalid/unknown commands in red
      enable = true;
      #patterns = {
      #  "rm -rf *" = "fg=white,bold,bg=red"; 
      #};
    };
    autosuggestion = { # shadow text suggested completions ahead of typing command
      enable = true;
      #highlight = "";
      #strategy = ["history"];
    };
    defaultKeymap = "viins";
    #initExtra = # added to zsh interactive shell (.zshrc)
    initContent = # added to zsh interactive shell (.zshrc)
    ''
      pfetch     
    '';
    shellAliases = {
      ls = "eza -all --long -g -h --color=always --group-directories-first --git";
      lsd = "eza -all --long -g -h --color=always --group-directories-first --git --total-size";
    };
    #zplug = {
    #  enable = true;
    #  plugins = [
    #    #{ name = "marlonrichert/zsh-autocomplete"; } # 
    #  ];
    #};
    history.size = 5000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };

}