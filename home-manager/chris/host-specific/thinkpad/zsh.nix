{ 
  config, 
  lib, 
  pkgs, 
  ... 
}: 

{
  
  programs.zsh = {
    initContent = # added to zsh interactive shell (.zshrc)
    ''
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
      flakeupdate = "sudo nix flake update --flake ~/nixos-configs";
      getnets = "iwctl station wlan0 get-networks";
      ledger = "cd /home/chris/nextcloud-client/Bond\\ Family/Financial/bond-ledger/ && nix develop";
      tsaspen = "sudo tailscale down && sleep 5 && sudo tailscale up -ssh --accept-routes --exit-node=${configVars.aspenTailscaleIp}";
      tsjuniper = "sudo tailscale down && sleep 5 && sudo tailscale up -ssh --accept-routes --exit-node=${configVars.juniperTailscaleIp}";
    };
  };

}