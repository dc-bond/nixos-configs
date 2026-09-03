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
        echo "Launching VNC viewer (press Ctrl+Alt+M for menu)..." && \
        vncviewer localhost:5900 \
          ViewOnly=0 \
          AcceptClipboard=1 \
          SendClipboard=1
        # kill the SSH tunnel after VNC session ends
        pkill -f "ssh.*kauri-vnc"
      }
      alder-desktop() {
        echo "Connecting to alder's desktop via VNC..."
        echo "Opening SSH tunnel to alder (port 5901)..."
        ssh -f -N alder-vnc && \
        sleep 1 && \
        echo "Launching VNC viewer (press Ctrl+Alt+M for menu)..." && \
        vncviewer localhost:5901 \
          ViewOnly=0 \
          AcceptClipboard=1 \
          SendClipboard=1
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
        echo "Writing CLAUDE.md pointer..."
        install -m 644 ${pkgs.writeText "nixos-top-CLAUDE.md" ''
          # CLAUDE.md

          `~/nixos/` is the directory Claude is always invoked from on cypress/thinkpad.
          It is not itself a repo — it holds two sibling git checkouts that are cloned
          fresh each boot by the `clone-configs` shell function (impermanence host):

          - `nixos-configs/` — public flake: hosts, `vars/default.nix`, `mkHost`, service
            modules. See [nixos-configs/CLAUDE.md](nixos-configs/CLAUDE.md) — this is the
            primary reference.
          - `nixos-configs-private/` — companion flake, consumed by the public repo as
            the `private` input; holds modules with personal data (HA automations,
            family web apps). See [nixos-configs-private/CLAUDE.md](nixos-configs-private/CLAUDE.md).

          Read both before acting on work that touches either repo.

          ## Tooling

          Installed host-wide on thinkpad, beyond coreutils: `python3` (bundled with
          `requests`, `pyyaml`, `openpyxl`), `jq`, `yq-go`, `sqlite`, `ripgrep`, `lsof`,
          `gh`, `pandoc`, `typst`, `poppler-utils`, `qpdf`, `ghostscript`, `imagemagick`
          and `tesseract` — see
          [nixos-configs/nixos-system/workstation-tools.nix](nixos-configs/nixos-system/workstation-tools.nix)
          — plus the baseline admin tools in
          [nixos-configs/nixos-system/base-tools.nix](nixos-configs/nixos-system/base-tools.nix).

          Anything else is one command away. Reach for the right tool rather than working
          around its absence:

          - `nix-shell -p <pkg> --run '<cmd>'`
          - `nix shell nixpkgs#<pkg> --command <cmd>`

          Both resolve offline against the pinned flake registry and take ~3s. Gotchas:

          - The Bash tool runs **zsh**, so unquoted globs in arguments hard-fail with
            `no matches found`. Write `grep -r --include="*.nix" .`, not `--include=*.nix`.
          - Flake installables can't take function application, so `nix shell` cannot build
            an ad-hoc python environment. Use the v1 form instead:
            `nix-shell -p 'python3.withPackages(ps: with ps; [ ps.pandas ])' --run '<cmd>'`.
          - Neither pandoc's typst engine nor imagemagick picks a default font here, despite
            39 being installed. `pandoc --pdf-engine=typst` dies with "font fallback list must
            not be empty" unless given `-V mainfont="DejaVu Sans"`, and `magick -annotate`
            needs an explicit `-font "$(fc-match -f '%{file}' 'DejaVu Sans')"`. Typst invoked
            directly on a `.typ` file is unaffected.

          This file is regenerated by `clone-configs`; edits here won't survive a reboot.
          To change it, edit the `pkgs.writeText` block in
          [nixos-configs/home-manager/chris/zsh.nix](nixos-configs/home-manager/chris/zsh.nix).
        ''} "$target_dir/CLAUDE.md"
        # project-scoped mcp config: the VSCodium claude-code extension spawns its own
        # bundled binary, bypassing the home-manager wrapper's --mcp-config flag, so
        # mcp-nixos only reaches the extension via .mcp.json at the project root
        echo "Writing .mcp.json pointer..."
        install -m 644 ${pkgs.writeText "nixos-top-mcp.json" (builtins.toJSON {
          mcpServers.nixos = {
            type = "stdio";
            command = lib.getExe pkgs.unstable.mcp-nixos;
          };
        })} "$target_dir/.mcp.json"
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
      flakeupall= "(cd $HOME/nixos/nixos-configs && nix flake update)";
      flakeupprivate= "(cd $HOME/nixos/nixos-configs && nix flake update private)";
      fetch-displaylink = "nix-prefetch-url --name displaylink-620.zip https://www.synaptics.com/sites/default/files/exe_files/2025-09/DisplayLink%20USB%20Graphics%20Software%20for%20Ubuntu6.2-EXE.zip";
    };
  };

}
