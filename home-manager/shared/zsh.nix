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
      nrun() {
        nix run nixpkgs#"$1" -- "''${@:2}"
      }
      nshell() {
        nix shell nixpkgs#"$1"
      }
    '';
    shellAliases = {
      ls = "eza -all --long -g -h --color=always --group-directories-first --git";
      lsd = "eza -all --long -g -h --color=always --group-directories-first --git --total-size";
      garbage = "nix-collect-garbage -d && sudo nix-collect-garbage -d";
      speed = "nix run nixpkgs#speedtest-rs";
      gens = "nixos-rebuild list-generations | head -n 5";
      yubigpg = ''gpg-connect-agent "scd serialno" "learn --force" /bye''; # force gpg to update its pointer towards whichever yubikey is plugged in
    };
    history.size = 5000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };

}