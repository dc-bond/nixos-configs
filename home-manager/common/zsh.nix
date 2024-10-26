{ 
  config, 
  lib, 
  pkgs, 
  ... 
}: 

{

  programs.zsh = {
    enable = true;
    #autocd = true; # move to directory without using cd
    #syntaxHighlighting.enable = true;
    enableCompletion = true;
    autoSuggestion = {
      enable = true;
      highlight = "fg=#ff00ff,bg=cyan,bold,underline";
      strategy = ["history"];
    };
    defaultKeymap = "viins";
    initExtra = # added to zsh interactive shell (.zshrc)
    ''
      pfetch     
    '';
    shellAliases = {
      ls = "eza -all --long -g -h --color=always --group-directories-first --git";
    };
    #zplug = {
    #  enable = true;
    #  plugins = [
    #    #{ name = "zsh-users/zsh-autosuggestions"; } # shadow text suggested completions ahead of typing
    #    #{ name = "marlonrichert/zsh-autocomplete"; } # show list of possible completions as typing
    #  ];
    #};
    history.size = 5000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };

}