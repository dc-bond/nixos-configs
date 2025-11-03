{ 
  config, 
  configVars,
  osConfig,
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
    '' + lib.optionalString (lib.elem osConfig.networking.hostName ["cypress" "thinkpad"]) ''
      reconnect-mouse() {
        echo "restarting bluetooth service..."
        sudo systemctl restart bluetooth
        sleep 3
        
        echo "power cycling bluetooth..."
        bluetoothctl power off
        sleep 2
        bluetoothctl power on
        sleep 3
        
        echo "reconnecting mouse..."
        bluetoothctl connect D3:CF:05:5D:88:79
        echo "Bluetooth reconnection complete!"
      }
      librewolf-private() {
        echo "launching LibreWolf..."
        librewolf --private-window "https://ipleak.net" "$@"
      }
    '';
    shellAliases = {
      ls = "eza -all --long -g -h --color=always --group-directories-first --git";
      lsd = "eza -all --long -g -h --color=always --group-directories-first --git --total-size";
      rbmain = "sudo nixos-rebuild switch --flake github:dc-bond/nixos-configs#$(hostname) --refresh";
      rbdev = "sudo nixos-rebuild switch --flake github:dc-bond/nixos-configs/dev#$(hostname) --refresh";
      garbage = "nix-collect-garbage -d && sudo nix-collect-garbage -d";
      speed = "nix run nixpkgs#speedtest-rs";
      gens = "nixos-rebuild list-generations | head -n 5";
    } // lib.optionalAttrs (lib.elem osConfig.networking.hostName ["cypress" "thinkpad"]) {
      flakeupdate = "sudo nix flake update --flake ~/nixos-configs";
      ledger = "cd /home/chris/nextcloud-client/Bond\\ Family/Financial/bond-ledger/ && nix develop";
      tsaspen = "sudo tailscale down && sleep 5 && sudo tailscale up --ssh --accept-routes --exit-node=${configVars.aspenTailscaleIp} --reset";
      tsjuniper = "sudo tailscale down && sleep 5 && sudo tailscale up --ssh --accept-routes --exit-node=${configVars.juniperTailscaleIp} --reset";
      tsdown = "sudo tailscale down";
      tsup = "sudo tailscale down && sleep 5 && sudo tailscale up --ssh --accept-routes --reset";
      cloneconfigs = "cd ~ && git clone https://github.com/dc-bond/nixos-configs";
    } // lib.optionalAttrs (osConfig.networking.hostName == "cypress") {
      storage = "cd /storage/WD-WX21DC86RU3P ; ls";
    } // lib.optionalAttrs (osConfig.networking.hostName == "thinkpad") {
      getnets = "iwctl station wlan0 get-networks";
    } // lib.optionalAttrs (osConfig.networking.hostName == "aspen") {
      storage = "cd /storage/WD-WCC7K4RU947F ; ls";
    };
    history.size = 5000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };

}