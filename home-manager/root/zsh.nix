{ 
  config, 
  lib, 
  pkgs, 
  ... 
}: 

{
  
  home.packages = with pkgs; [
    eza # modern replacement for 'ls'
    pfetch # system info displayed on shell startup
  ];

  programs.zsh = {
    enable = true;
    syntaxHighlighting = { # highlight valid commands in green and invalid/unknown commands in red
      enable = true;
    };
    autosuggestion = { # shadow text suggested completions ahead of typing command
      enable = true;
    };
    defaultKeymap = "viins";
    initContent = # added to zsh interactive shell (.zshrc)
    ''
      pfetch     
    '';
    shellAliases = {
      ls = "eza -all --long -g -h --color=always --group-directories-first --git";
      lsd = "eza -all --long -g -h --color=always --group-directories-first --git --total-size";
      rbmain = "sudo nixos-rebuild switch --flake github:dc-bond/nixos-configs#$(hostname) --refresh";
      rbdev = "sudo nixos-rebuild switch --flake github:dc-bond/nixos-configs/dev#$(hostname) --refresh";
      garbage = "nix-collect-garbage -d && sudo nix-collect-garbage -d";
    };
    history.size = 5000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };

}