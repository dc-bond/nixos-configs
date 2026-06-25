# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a production NixOS configuration managing a multi-host homelab and VPS infrastructure using Nix flakes. The main configuration is in the `nixos-configs/` directory and manages 5+ hosts running 40+ self-hosted services.

**Main Configuration Directory**: `nixos-configs/`

## IMPORTANT: Command Execution Context

**Claude only runs on workstations (cypress or thinkpad).** Do NOT run host-changing commands (`nixos-rebuild`, package installs, service restarts that alter state) directly against aspen/juniper/kauri — the user drives those rebuilds through their normal flow.

**However, Claude has SSH access to all hosts via Tailscale** and should use it directly for read-only investigation: log checks, `systemctl status`, file inspection, backup verification, etc. Don't ask the user to paste log output you can fetch yourself with `ssh <host> '<command>'`. Use `sudo` over SSH where needed.

**Rule of thumb:**
- **Read-only / diagnostic**: SSH in and run it yourself.
- **State-changing on a remote host**: suggest the command, let the user run it as part of their rebuild/deploy workflow.


## High-Level Architecture

### Repository Structure

The repository uses a **centralized configuration** approach where almost all host-specific metadata lives in `vars/default.nix`. This 500+ line file is the single source of truth for:
- Host networking configuration (IPs, interfaces, SSH ports, Tailscale settings)
- User accounts and credentials
- Device registry (phones, cameras, IoT devices)
- Container subnet allocations
- Domain names and DNS settings

### Key Architectural Patterns

1. **Auto-Generation via `mkHost` Function** (`flake.nix:49-75`)
   - The flake defines a `mkHost` function that generates complete NixOS configurations
   - All hosts are auto-generated from `configVars.hosts` using `lib.mapAttrs`
   - Each host automatically includes home-manager configs for all users + root
   - Users are auto-detected from the directory structure: `hosts/${hostname}/${user}/home.nix`

2. **Modular Service Imports**
   - Reusable service modules live in `nixos-system/`
   - Each host's `configuration.nix` selectively imports needed modules
   - Module dependencies are documented in comments (e.g., `# requires mysql.nix`)

3. **Hybrid Service Approach**
   - Native NixOS modules for mature services (Nextcloud, Traefik, PostgreSQL)
   - OCI containers (`oci-*.nix`) for services lacking good Nix modules
   - All OCI services are declaratively configured using Docker Compose-style syntax

4. **Centralized Variable Access**
   - All modules receive `specialArgs`: `inputs`, `configVars`, `configLib`, `outputs`
   - Access host config: `configVars.hosts.${config.networking.hostName}`
   - Access user config: `configVars.users.chris`
   - Access container subnets: `configVars.ociServices.pihole.subnet`

### Critical Files

- **`vars/default.nix`**: Single source of truth for all configuration metadata
- **`README.md`**
- **`nixos-system/networking.nix`**
- **`flake.nix`**: Flake entrypoint with `mkHost` auto-generation function
- **`lib/default.nix`**: Custom helper functions
  - `relativeToRoot`: Convert relative paths for clean imports
  - `scanPaths`: Recursively scan directories for `.nix` files
- **`hosts/${hostname}/configuration.nix`**: Per-host system configuration
- **`hosts/${hostname}/${user}/home.nix`**: Per-user home-manager configuration

### Data Flow

1. **Flake Inputs** → Define nixpkgs versions, home-manager, sops-nix, etc.
2. **`vars/default.nix`** → Loaded as `configVars` and passed to all modules
3. **`mkHost` function** → Generates NixOS system for each host in `configVars.hosts`
4. **Host `configuration.nix`** → Imports relevant service modules from `nixos-system/`
5. **Service modules** → Access host metadata from `configVars.hosts.${hostname}`
6. **Secrets** → Decrypted at boot to `/run/secrets/` using SOPS/age

### Networking Architecture

**DNS: High-Availability Dual Pi-hole Setup**
- **aspen** (192.168.1.2): LAN DNS server (~90% uptime)
- **juniper** (VPS): Public DNS server (~99% uptime)
- Both run identical Pi-hole + Unbound configurations declared in `oci-pihole.nix`
- Tailscale clients use juniper as primary DNS for reliability
- LAN-only devices use aspen via DHCP with fallback servers

**DNS Failover Behavior (Tested 2026-02-18)**

*NixOS Hosts with systemd-resolved:*
- **DHCP Configuration Required**: UniFi DHCP must advertise all 3 DNS servers:
  - Primary: 192.168.1.2 (aspen pihole)
  - Secondary: 1.1.1.1 (Cloudflare)
  - Tertiary: 9.9.9.9 (Quad9)
- **Failover on LAN (Tailscale OFF)**:
  - When aspen goes down: First query may take ~5s timeout before failing over to 1.1.1.1, but systemd-resolved can also detect aspen as unreachable proactively (observed: no timeout after ~30s of aspen being offline)
  - Subsequent queries: Instant - systemd-resolved learns and switches Current DNS Server
  - Local domains (*.opticon.dev): FAIL (public DNS doesn't know them)
  - Internet connectivity: Works perfectly via fallback DNS
- **Failover via Tailscale (Tailscale ON)**:
  - Uses 100.100.100.100 (Tailscale MagicDNS) which routes queries to juniper's pihole
  - No timeouts - seamless failover
  - Local domains: WORK (juniper has identical custom DNS entries)
  - Internet connectivity: Works perfectly
  - **Recommended**: Keep Tailscale enabled on mobile devices for best experience
- **Failback after Tailscale UP/DOWN cycle**:
  - systemd-resolved retains "aspen is unreachable" state across Tailscale interface changes
  - After Tailscale disconnects, fallback DNS (1.1.1.1) is used immediately with no timeout
  - Tested: both first and subsequent queries after Tailscale disconnect were instant (0s)
- **Failback (when aspen returns)**:
  - Automatic failback is SLOW - systemd-resolved may stay on fallback server for minutes to hours
  - Natural failback occurs on: DHCP renewal (12-24h), network reconnection, or reboot
  - Force immediate failback: `sudo systemctl restart systemd-resolved`
  - This conservative behavior is by design - avoids repeated timeouts to recently-failed servers
  - In practice: Not a problem since fallback DNS works perfectly for public internet

*Important Notes:*
- systemd-resolved's "Fallback DNS" only activate when NO DNS servers are configured on any link
- DNS servers from DHCP take priority over global fallbacks
- Stale DHCP leases may need refresh after changing UniFi DHCP DNS settings:
  - **NixOS/Linux**: `sudo systemctl restart systemd-networkd`
  - **iOS/iPhone**: Settings → Wi-Fi → (i) → Renew Lease
  - **Android**: Forget network and reconnect, or toggle airplane mode
- Check current DNS config: `resolvectl status` (Linux) or Wi-Fi settings (mobile)

**Tailscale Integration**
- Exit nodes: aspen, juniper (advertise LAN routes)
- Clients with exit node: thinkpad, kauri (use aspen as default exit)
- Clients without exit node: cypress (--ssh --accept-routes only, no --exit-node configured)
- Configuration per-host in `configVars.hosts.${hostname}.networking.tailscale`
- Module: `nixos-system/tailscale.nix`

**SSH Access**
- Servers (aspen, juniper): Custom SSH ports defined in configVars
- Workstations/laptops: Tailscale SSH only (`sshPort = null`)
- Public keys stored in `configVars.hosts.${hostname}.networking.sshPublicKey`

### Storage and Backups

**Disk Layouts**
- BTRFS with optional LUKS encryption
- Declarative partitioning via disko (`disko.nix` in host directories)
- Some hosts use impermanence architecture (ephemeral root filesystem)

**Backup Strategy** (`nixos-system/backups.nix`)
- Nightly borgbackup to local storage (encrypted with repokey-blake2)
- Cloud sync to Backblaze B2 via rclone
- Weekly full data verification (Sundays)
- Email/webhook notifications on success/failure
- Per-service backup integration: services append paths to borg job with `lib.mkAfter`

### Secrets Management

- **SOPS** with **age** encryption (not PGP)
- Encrypted secrets file: `secrets.yaml`
- Per-host age keys: `/etc/age/${hostname}-age.key`
- Secrets decrypted at boot to `/run/secrets/`
- Usage pattern:
  ```nix
  sops.secrets.secretName = {
    owner = config.users.users.username.name;
    mode = "0440";
  };
  # Reference: config.sops.secrets.secretName.path
  ```

### Service Organization

**Native NixOS Services** (40+ modules in `nixos-system/`)
- Foundation: `foundation.nix`, `networking.nix`, `boot.nix`, `users.nix`
- Infrastructure: `traefik.nix`, `backups.nix`, `sops.nix`, `tailscale.nix`
- Databases: `postgresql.nix`, `mysql.nix`
- Applications: `nextcloud.nix`, `photoprism.nix`, `home-assistant.nix`, `vaultwarden.nix`
- Desktop: `hyprland.nix`, `labwc.nix`, `greetd.nix`

**OCI Container Services** (`oci-*.nix` modules)
- DNS: `oci-pihole.nix`
- Media: `oci-media-server.nix` (Jellyfin, Sonarr, Radarr)
- Home Automation: `oci-frigate.nix`, `oci-zwavejs.nix`
- Productivity: `oci-actual.nix`, `oci-fava.nix`, `oci-n8n.nix`, `oci-librechat.nix`
- Infrastructure: `oci-unifi.nix`, `oci-searxng.nix`

## Hosts Overview

- **aspen**: Homelab server (headless, 192.168.1.2), monitoring hub, exit node, build server for other hosts, runs 30+ services
- **juniper**: VPS (headless, 178.156.133.218), public services, primary DNS, exit node
- **thinkpad**: ThinkPad laptop (Hyprland, encrypted), primary workstation
- **cypress**: Desktop workstation (Hyprland)
- **kauri**: Family laptop (Labwc, encrypted), secondary user

## Key Services

- **Reverse Proxy**: Traefik with Let's Encrypt, automatic TLS certificates
- **DNS**: Pi-hole + Unbound (ad blocking + recursive DNS)
- **Auth**: Authelia (SSO), LLDAP (LDAP directory)
- **Storage**: Nextcloud, Photoprism, Calibre
- **Monitoring**: Prometheus, Grafana, Uptime Kuma
- **Home Automation**: Home Assistant, Frigate, Zwavejs
- **Media**: Jellyfin, Sonarr, Radarr, Prowlarr, SABnzbd
- **Productivity**: Actual Budget, Fava, RecipeSage, N8N, LibreChat
- **Security**: Vaultwarden, CrowdSec

## Notes for AI Assistants

1. **Always check `vars/default.nix` first** - It contains most configuration metadata
2. **Use `configLib.relativeToRoot`** for all imports - Ensures portability
3. **Follow existing patterns** - Study similar modules before creating new ones
4. **Document dependencies** - Add comments for module dependencies
6. **Secrets via SOPS only** - Never commit plaintext secrets
7. **Integrate with backups** - Add important paths to borgbackup jobs
8. **Traefik labels** - OCI services need proper labels for reverse proxy routing
9. **Check private modules** - Some features may be in the private config repo
10. **Working directory** - Main config is in `nixos-configs/` subdirectory
11. **Commit messages** - Plain concise subject line, lowercase imperative. Do **not** append `Co-Authored-By: Claude ...` trailers.