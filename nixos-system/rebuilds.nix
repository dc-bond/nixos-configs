{ 
  config,
  configVars,
  ... 
}:

{
  
  # deploy the private SSH key for root
  sops.secrets.builderSshKey = {
    mode = "0600";
    owner = "root";
    group = "root";
    path = "/root/.ssh/id_builder";
  };
  
  # configure distributed builds to use aspen, note "trusted-users" setting in foundation.nix imported into aspen
  nix = {
    distributedBuilds = true;
    buildMachines = [{
      hostName = configVars.hosts.aspen.networking.tailscaleIp;
      systems = [ "x86_64-linux" ];
      protocol = "ssh-ng";
      maxJobs = 8; # use 8 of 12 cores for parallel building, leave headroom for services running on aspen
      speedFactor = 2; # prefer aspen over local (higher = more preferred)
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      sshUser = "chris";
      sshKey = "/root/.ssh/id_builder";
    }];
    extraOptions = ''
      builders-use-substitutes = true
    '';
    settings.connect-timeout = 5;
  };
  
  # rb() - rebuild any host's configuration, available to all users in interactive zsh shells
  programs.zsh.interactiveShellInit = ''
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

}

# ═══════════════════════════════════════════════════════════════════════════════
# DISTRIBUTED BUILDS MODULE
# ═══════════════════════════════════════════════════════════════════════════════
#
# This module configures this host to:
# 1. Offload heavy Nix builds to aspen automatically
# 2. Provide the rb() shell function for deploying configs to any host
#
# ═══════════════════════════════════════════════════════════════════════════════
# EXECUTION FLOW: rb <hostname>
# ═══════════════════════════════════════════════════════════════════════════════
#
# 1. rb() FUNCTION (shell script)
#    ├─ Tests SSH connectivity to target host:
#    │  ├─ Try: ssh <hostname>-tailscale (port 22)
#    │  └─ Fallback: ssh <hostname> (custom port from configVars)
#    └─ Calls: sudo nixos-rebuild switch --target-host <chosen-connection>

# 2. NIXOS-REBUILD + BUILD PHASE (runs on cypress as root)
#    ├─ Evaluates: flake configuration for target host (locally on cypress)
#    ├─ Determines: what derivations need to be built
#    ├─ Calls: nix-daemon (on cypress) to build required derivations
#    │
#    └─ NIX-DAEMON DISTRIBUTED BUILD (orchestrated by cypress):
#       ├─ Sees: distributedBuilds = true
#       ├─ For each derivation to build:
#       │  ├─ Attempts: ssh chris@<aspen-tailscale-ip> (using /root/.ssh/id_builder)
#       │  ├─ If SUCCESS → Compilation executes on aspen
#       │  ├─ If FAIL (timeout 5s) → Compilation executes on cypress as fallback
#       │  └─ Returns: completed derivation to cypress
#       └─ Result: Full closure assembled on cypress, ready for deployment
#
# 3. NIXOS-REBUILD DEPLOYMENT
#    ├─ Takes: completed build closure
#    ├─ Copies: closure to target host via SSH (uses connection from step 1)
#    └─ Activates: new configuration on target host
#
# ═══════════════════════════════════════════════════════════════════════════════
# INSIGHT: Two Independent SSH Connections
# ═══════════════════════════════════════════════════════════════════════════════
#
# Connection A: nix-daemon → aspen (for building)
#   - Uses: /root/.ssh/id_builder
#   - Target: aspen tailscale IP only
#   - Purpose: Offload compilation work
#   - Failure mode: Build locally instead (graceful degradation)
#
# Connection B: nixos-rebuild → target host (for copying/activating)
#   - Uses: chris's yubikey via gpg-agent (from rb() function context)
#   - Target: tailscale OR regular SSH (rb() tests and chooses)
#   - Purpose: Deploy built configuration
#   - Failure mode: rb() handles fallback to regular SSH
#
# These operate independently and at different stages, which is why Connection B
# can succeed with regular SSH fallback even when Connection A (tailscale-only) fails.
#
# ═══════════════════════════════════════════════════════════════════════════════