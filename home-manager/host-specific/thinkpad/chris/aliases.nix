{ 
  pkgs,
  config,
  configVars,
  ... 
}: 

{

  programs.zsh = {

    shellAliases = {
      rb = "sudo nixos-rebuild switch --flake github:dc-bond/nixos-configs#thinkpad --refresh";
      flakeupdate = "sudo nix flake update --flake ~/nixos-configs";
      garbage = "nix-collect-garbage -d && sudo nix-collect-garbage -d";
      getnets = "iwctl station wlan0 get-networks";
      ledger = "cd /home/chris/nextcloud-client/Bond\\ Family/Financial/bond-ledger/ && nix develop";
      speed = "nix run nixpkgs#speedtest-rs";
    };

    initContent = ''

      reconnect-mouse() {
        echo "Restarting Bluetooth service ..."
        sudo systemctl restart bluetooth
        sleep 3
        
        echo "Power cycling Bluetooth ..."
        bluetoothctl power off
        sleep 2
        bluetoothctl power on
        sleep 3
        
        echo "Reconnecting mouse..."
        bluetoothctl connect D3:CF:05:5D:88:75
        echo "Bluetooth reconnection complete!"
      }

      librewolf-private() {
        cleanup() {
          echo "LibreWolf closed. Deactivating remote Tailscale exit node ..."
          sudo ${pkgs.tailscale}/bin/tailscale up --ssh --accept-routes --exit-node=${configVars.aspenTailscaleIp} 2>/dev/null || true
          echo "Done."
        }
        trap cleanup RETURN
        
        echo "Activating remote Tailscale exit node..."
        sudo ${pkgs.tailscale}/bin/tailscale up --ssh --accept-routes --exit-node=${configVars.juniperTailscaleIp}
        
        echo "Launching LibreWolf ..."
        librewolf --private-window "https://ipleak.net" "$@"
      }

    '';

  };

}