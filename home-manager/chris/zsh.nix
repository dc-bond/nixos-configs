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
      rb() {
        local selected_host
        local available_hosts
        local flake_dir="$HOME/nixos-configs"
        
        # get list of hosts from flake
        available_hosts=($(nix eval "$flake_dir#nixosConfigurations" --apply 'builtins.attrNames' --json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[]'))
        
        if [ ''${#available_hosts[@]} -eq 0 ]; then
          echo "Error: Could not find any hosts in flake"
          return 1
        fi
        
        # select host (interactive or argument)
        if [ $# -eq 0 ]; then
          echo "Available hosts:"
          select selected_host in "''${available_hosts[@]}"; do
            if [ -n "$selected_host" ]; then
              break
            fi
          done
        else
          selected_host="$1"
          if [[ ! " ''${available_hosts[@]} " =~ " ''${selected_host} " ]]; then
            echo "Error: Host '$selected_host' not found"
            echo "Available hosts: ''${available_hosts[*]}"
            return 1
          fi
        fi
        
        # local rebuild
        if [ "$selected_host" = "$(hostname)" ]; then
          echo "→ Rebuilding local host $selected_host..."
          sudo nixos-rebuild switch --flake "$flake_dir#$selected_host"
          return $?
        fi
        
        # find connection for remote host
        local ssh_target=""
        
        echo "→ Attempting Tailscale connection ($selected_host-tailscale)..."
        if ssh -o ConnectTimeout=5 -o BatchMode=yes "$selected_host-tailscale" exit 2>/dev/null; then
          ssh_target="$selected_host-tailscale"
          echo "✓ Connected via Tailscale"
        else
          local ssh_port=$(nix eval "$flake_dir#configVars.hosts.$selected_host.networking.sshPort" 2>/dev/null)
          
          if [ "$ssh_port" != "null" ] && [ -n "$ssh_port" ]; then
            echo "→ Tailscale failed, trying regular SSH ($selected_host:$ssh_port)..."
            if ssh -o ConnectTimeout=5 -o BatchMode=yes "$selected_host" exit 2>/dev/null; then
              ssh_target="$selected_host"
              echo "✓ Connected via regular SSH"
            else
              echo "✗ Could not connect to $selected_host"
              return 1
            fi
          else
            echo "✗ Tailscale connection failed and host has no regular SSH configured"
            return 1
          fi
        fi
        
        # remote rebuild
        echo "→ Rebuilding $selected_host..."
        NIX_SSHOPTS="-o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=3" \
        nixos-rebuild switch \
          --flake "$flake_dir#$selected_host" \
          --target-host "$ssh_target" \
          --use-remote-sudo \
          -v
      }
    '';
    shellAliases = {
    } // lib.optionalAttrs (lib.elem osConfig.networking.hostName ["cypress" "thinkpad"]) {
      flakeupdate = "sudo nix flake update --flake ~/nixos-configs";
      ledger = "cd /home/chris/nextcloud-client/Bond\\ Family/Financial/bond-ledger/ && nix develop --command codium . && cd ~";
      finplanner = "cd /home/chris/nextcloud-client/Bond\\ Family/Financial/finplanner/ && nix develop";
      cloneconfigs = "cd ~ && git clone https://github.com/dc-bond/nixos-configs";
    } // lib.optionalAttrs (osConfig.networking.hostName == "cypress") {
      storage = "cd /storage/WD-WX21DC86RU3P ; ls";
    } // lib.optionalAttrs (osConfig.networking.hostName == "aspen") {
      storage = "cd /storage/WD-WCC7K4RU947F ; ls";
    };
  };

}