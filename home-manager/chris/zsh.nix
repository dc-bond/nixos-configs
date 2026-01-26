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
    initContent = lib.optionalString (lib.elem osConfig.networking.hostName ["cypress" "thinkpad"]) # added to zsh interactive shell (.zshrc)
    ''
      librewolf-private() {
        echo "launching LibreWolf..."
        librewolf --private-window "https://ipleak.net" "$@"
      }
      ssh-temp() {
        if [ -z "$1" ]; then
          echo "Usage: ssh-temp [user@]host"
          echo "Temporarily SSH to a host, bypassing declarative known_hosts"
          return 1
        fi
        ssh -o GlobalKnownHostsFile=/dev/null -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "$@"
      }
      kauri-desktop() {
        echo "Connecting to kauri's desktop via VNC..."
        echo "Opening SSH tunnel to kauri (port 5900)..."
        ssh -f -N kauri-vnc && \
        sleep 1 && \
        echo "Launching VNC viewer (press F8 for menu)..." && \
        vncviewer localhost:5900 \
          ViewOnly=0 \
          AcceptClipboard=1 \
          SendClipboard=1 \
          MenuKey=F8
        # kill the SSH tunnel after VNC session ends
        pkill -f "ssh.*kauri-vnc"
      }
      alder-desktop() {
        echo "Connecting to alder's desktop via VNC..."
        echo "Opening SSH tunnel to alder (port 5901)..."
        ssh -f -N alder-vnc && \
        sleep 1 && \
        echo "Launching VNC viewer (press F8 for menu)..." && \
        vncviewer localhost:5901 \
          ViewOnly=0 \
          AcceptClipboard=1 \
          SendClipboard=1 \
          MenuKey=F8
        # kill the SSH tunnel after VNC session ends
        pkill -f "ssh.*alder-vnc"
      }
    '';
    shellAliases = {
    } // lib.optionalAttrs (lib.elem osConfig.networking.hostName ["cypress" "thinkpad"]) {
      ledger = "cd /home/chris/nextcloud-client/Bond\\ Family/Financial/bond-ledger/ && nix develop --command codium . && cd ~";
      finplannerdev = "cd /home/chris/nextcloud-client/Bond\\ Family/Financial/finplanner/ && nix develop";
      chrisworkoutdev = "cd /home/chris/nextcloud-client/Personal/misc/chris-workouts/ && nix develop";
      danielleworkoutdev = "cd /home/chris/nextcloud-client/Personal/misc/danielle-workouts/ && nix develop";
      cloneconfigs = "cd $HOME/nextcloud-client/Personal/nixos && git clone https://github.com/dc-bond/nixos-configs";
      configs = "cd $HOME/nextcloud-client/Personal/nixos/nixos-configs";
      flakeupdate= "(cd $HOME/nextcloud-client/Personal/nixos/nixos-configs && nix flake update)";
    # } // lib.optionalAttrs (osConfig.networking.hostName == "cypress") {
    #   storage = "cd /data-pool-hdd ; ls";
    } // lib.optionalAttrs (osConfig.networking.hostName == "aspen") {
      storage = "cd /data-pool-hdd ; ls";
    };
  };

}