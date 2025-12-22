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

      jlog() {
        journalctl -e -u "$1" --since "''${2:-1 day ago}" --no-pager --follow
      }

      rollback() {
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "        NixOS Generation Rollback"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        CURRENT_GEN=$(nixos-rebuild list-generations | grep current | awk '{print $1}')
        echo "Current generation: $CURRENT_GEN"
        echo ""

        echo "Available generations:"
        nixos-rebuild list-generations | head -n 5 | nl -w2 -s') '
        echo ""

        echo "Select a generation to rollback to:"
        echo "  - Enter a number (1-5) to select from the list above"
        echo "  - Enter 'prev' to rollback to previous generation"
        echo "  - Enter 'q' to cancel"
        echo ""
        read "selection?Selection: "

        if [[ "$selection" == "q" || "$selection" == "Q" ]]; then
          echo "Rollback cancelled."
          return 0
        fi

        if [[ "$selection" == "prev" ]]; then
          echo ""
          echo "Rolling back to previous generation..."
          sudo nix-env --rollback --profile /nix/var/nix/profiles/system
          sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
          echo ""
          echo "✓ Rollback complete!"
          echo ""
          echo "New current generation:"
          nixos-rebuild list-generations | grep current
          return 0
        fi

        if [[ "$selection" =~ ^[0-9]+$ ]]; then
          GENERATION=$(nixos-rebuild list-generations | head -n 5 | sed -n "''${selection}p" | awk '{print $1}')

          if [ -z "$GENERATION" ]; then
            echo "Invalid selection."
            return 1
          fi

          echo ""
          echo "Selected generation: $GENERATION"
          echo ""
          read "confirm?Are you sure you want to rollback to generation $GENERATION? (y/N): "

          if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Rollback cancelled."
            return 0
          fi

          echo ""
          echo "Rolling back to generation $GENERATION..."
          sudo /nix/var/nix/profiles/system-$GENERATION-link/bin/switch-to-configuration switch
          echo ""
          echo "✓ Rollback complete!"
          echo ""
          echo "New current generation:"
          nixos-rebuild list-generations | grep current
          return 0
        fi

        echo "Invalid selection."
        return 1
      }

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
      speed = "nix run nixpkgs#speedtest-rs";
      yubigpg = ''gpg-connect-agent "scd serialno" "learn --force" /bye''; # force gpg to update its pointer towards whichever yubikey is plugged in
      garbage = "nix-collect-garbage --delete-older-than 7d && sudo nix-collect-garbage --delete-older-than 7d";
    };
    history.size = 5000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };

}