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
    initContent =
    (lib.optionalString (lib.elem osConfig.networking.hostName ["cypress" "thinkpad"]) ''
      wolftmp() {
        echo "switching to juniper exit node..."
        tupjuniper
        echo "launching ephemeral LibreWolf (firejail sandboxed + tmpfs)..."
        /run/current-system/sw/bin/librewolf-tmpjail --private-window "https://ipleak.net" "$@"
        echo "restoring default exit node..."
        tup
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
      clone-configs() {
        local target_dir="$HOME/nixos"
        if [ -d "$target_dir" ]; then
          echo "Error: $target_dir already exists"
          return 1
        fi
        echo "Creating $target_dir..."
        mkdir -p "$target_dir"
        cd "$target_dir"
        echo "Cloning nixos-configs..."
        git clone git@github.com:dc-bond/nixos-configs.git
        echo "Cloning nixos-configs-private..."
        git clone git@github.com:dc-bond/nixos-configs-private.git
        echo "Copying CLAUDE.md to $target_dir..."
        cp nixos-configs-private/CLAUDE.md "$target_dir/"
        echo "Done"
      }
    '');
    shellAliases = {
    } // lib.optionalAttrs (lib.elem osConfig.networking.hostName ["cypress" "thinkpad"]) {
      ledger = "cd /home/chris/nextcloud-client/Bond\\ Family/Financial/bond-ledger/ && nix develop --command codium . && cd ~";
      finplannerdev = "cd /home/chris/nextcloud-client/Bond\\ Family/Financial/finplanner/ && nix develop";
      chrisworkoutdev = "cd /home/chris/nextcloud-client/Personal/misc/chris-workouts/ && nix develop";
      danielleworkoutdev = "cd /home/chris/nextcloud-client/Personal/misc/danielle-workouts/ && nix develop";
      configs = "cd $HOME/nixos";
      flakeupdate= "(cd $HOME/nextcloud-client/Personal/nixos/nixos-configs && nix flake update)";
      fetch-displaylink = "nix-prefetch-url --name displaylink-620.zip https://www.synaptics.com/sites/default/files/exe_files/2025-09/DisplayLink%20USB%20Graphics%20Software%20for%20Ubuntu6.2-EXE.zip";
    };
  };

}