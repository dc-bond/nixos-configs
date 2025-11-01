# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive NixOS configuration repository using Nix flakes for declarative system management across multiple hosts. The repository manages four distinct hosts (thinkpad, cypress, aspen, juniper) with shared configurations and modular architecture.

## Architecture

### Flake Structure
- **flake.nix**: Central entry point defining NixOS configurations for all hosts using nixpkgs 25.05
- **inputs**: nixpkgs, home-manager, plasma-manager, sops-nix, disko, firefox-addons
- **vars/default.nix**: Centralized variables for IPs, domains, user info, and network configuration
- **lib/default.nix**: Custom utility functions for path manipulation and directory scanning

### Directory Structure
- **hosts/**: Per-host configurations with individual config files and home-manager setups
- **nixos-system/**: Shared system modules (audio, networking, services, etc.)
- **home-manager/**: User dotfiles and application configurations
- **scripts/**: Deployment scripts for each host using nixos-anywhere
- **overlays/**: Custom package modifications and additions
- **deprecated/**: Archived configurations no longer in use

### Key Features
- **Secrets Management**: sops-nix with Age encryption, keys stored in /etc/age/
- **Home Management**: home-manager integration for user configurations
- **Self-hosted Services**: Traefik reverse proxy, Nextcloud, Jellyfin, Matrix, etc.
- **Container Stack**: Docker-based services with proper networking isolation
- **Automatic SSL**: Let's Encrypt certificates via Traefik and Cloudflare DNS
- **Backup System**: BorgBackup integration with service recovery scripts

## Common Commands

### System Operations
```bash
# Rebuild current host configuration
sudo nixos-rebuild switch --flake .

# Test configuration without switching
sudo nixos-rebuild test --flake .

# Build specific host configuration
nix build .#nixosConfigurations.thinkpad.config.system.build.toplevel

# Update flake inputs
nix flake update

# Check flake status
nix flake check
```

### Deployment
```bash
# Deploy to remote hosts (scripts are available as system packages)
deployThinkpad  # Available when script is imported
deployCypress
deployJuniper
deployAspen

# Manual deployment using nixos-anywhere
nix run github:nix-community/nixos-anywhere -- --flake '.#hostname' root@ip.address
```

### Development Tools
```bash
# View dependency tree
nix-tree

# Search for packages
nix search nixpkgs packagename

# Enter development shell with specific packages
nix shell nixpkgs#package1 nixpkgs#package2
```

### Secrets Management
- Secrets are encrypted with sops-nix using Age keys
- Host keys: `/etc/age/{hostname}-age.key`
- User keys: `~/.config/age/{username}-age.key`
- Edit secrets: `sops secrets.yaml`

## Configuration Patterns

### Adding New Services
1. Create module in `nixos-system/` directory
2. Define service configuration with proper networking/firewall rules
3. Add to relevant host's imports in `hosts/{hostname}/configuration.nix`
4. Include backup paths if service stores data

### Host-Specific Configuration
- Each host has its own `configuration.nix` with specific hardware and service imports
- Use `configVars` for consistent IP addresses, domains, and user information
- Host options are defined using lib.mkOption for type safety

### Container Services
- Docker containers use isolated subnets defined in vars/default.nix
- Traefik provides automatic SSL termination and routing
- Each service typically gets its own subnet range (e.g., 172.21.x.0/25)

### Home Manager Integration
- User configurations in `home-manager/{username}/`
- Separate configs for chris and root users
- Per-host home.nix files import relevant user modules

## Important Notes

- System state version tracks initial NixOS installation version for compatibility
- Hardware configurations are auto-generated during deployment
- Tailscale provides secure remote access between hosts
- All services behind Traefik require explicit middleware configuration
- Deployment scripts handle Age key provisioning from password store