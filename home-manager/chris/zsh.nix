{ 
  config, 
  configVars,
  osConfig,
  lib, 
  pkgs, 
  ... 
}: 

{
  

  programs.zsh = {
    initContent = # added to zsh interactive shell (.zshrc)
    ''
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
    } // lib.optionalAttrs (lib.elem osConfig.networking.hostName ["cypress" "thinkpad"]) {
      flakeupdate= "(cd $HOME/nextcloud-client/Personal/nixos/nixos-configs && nix flake update)";
      ledger = "cd /home/chris/nextcloud-client/Bond\\ Family/Financial/bond-ledger/ && nix develop --command codium . && cd ~";
      finplannerdev = "cd /home/chris/nextcloud-client/Bond\\ Family/Financial/finplanner/ && nix develop";
      chrisworkoutdev = "cd /home/chris/nextcloud-client/Personal/misc/chris-workouts/ && nix develop";
      danielleworkoutdev = "cd /home/chris/nextcloud-client/Personal/misc/danielle-workouts/ && nix develop";
      cloneconfigs = "cd ~ && git clone https://github.com/dc-bond/nixos-configs";
    } // lib.optionalAttrs (osConfig.networking.hostName == "cypress") {
      storage = "cd /storage/WD-WX21DC86RU3P ; ls";
    } // lib.optionalAttrs (osConfig.networking.hostName == "aspen") {
      storage = "cd /storage/WD-WCC7K4RU947F ; ls";
    };
  };

}