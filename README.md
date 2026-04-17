# NixOS Configuration
<a href="https://nixos.org/">
  <img width="101" height="20" alt="NixOS" src="https://github.com/user-attachments/assets/100e6b95-643d-40f1-87ed-ccb214c61015" />
</a>

This repository contains the declarative configuration for my NixOS systems.

## Highlights
- ❄️ Nix flakes handle upstream dependencies and track latest stable release of Nixpkgs
- 🏠 [home-manager](https://github.com/nix-community/home-manager) manages dotfiles and user-specific configurations
- 🤫 [sops-nix](https://github.com/Mic92/sops-nix) manages secrets with age encryption
- ☁️ Self-hosted services including Nextcloud, Authelia, Matrix, Photoprism, and 40+ others
- 🔒  Automatic Let's Encrypt certificate registration and renewal with [Traefik](https://traefik.io/traefik) reverse proxy  
- 🐳 Hybrid approach: native NixOS services + OCI [docker] containers for select applications where native nix modules either don't exist or are incomplete
- 🧩 Modular architecture facilitates quick deployment of services across different hosts
- 🌐 Dual Pi-hole + Unbound DNS setup with automatic failover via Tailscale
- 💾 Declarative disk management with BTRFS and LUKS encryption
- 🚀 Distributed builds leverage remote server for fast parallel compilation

## Repository Structure
```
nixos-configs/
├── flake.nix                    # Flake entrypoint
├── flake.lock                   # Locked dependency versions
│
├── hosts/                       # Per-machine configurations
│   ├── <hostname>/
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   ├── disko.nix      # Declarative disk layouts (OS + data storage)
│   │   └── <user>/home.nix
│
├── nixos-system/                # Reusable system-level service modules
│   ├── nextcloud.nix
│   ├── photoprism.nix
│   ├── uptime-kuma.nix
│   ├── matrix-synapse.nix
│   ├── oci-*.nix                # Dockerized services
│   └── [40+ other modules]
│
├── home-manager/                # User-specific configurations
│   └── <user>/
│       ├── plasma.nix
│       ├── alacritty.nix
│       ├── firefox.nix
│       └── [other programs]
│
├── lib/                         # Custom functions and utilities
├── overlays/                    # Package overlays and modifications
├── vars/                        # Shared variables
├── scripts/                     # Deployment and maintenance scripts
├── secrets.yaml                 # SOPS-encrypted secrets
└── .sops.yaml                   # SOPS configuration
```

## Overall Architecture

This configuration spans multiple machine types:
- **Homelab servers**: Primary service hosts running self-hosted applications
- **VPS instances**: Public-facing services that work better when not behind NAT and/or require 99% uptime
- **Workstations**: Desktop and laptop configurations with GUI environments
- **Specialized hosts**: Various other systems with specific purposes

Each host is defined in `hosts/<hostname>/` and can selectively import service modules from `nixos-system/` as needed. User configurations are managed separately through home-manager, allowing different users to have distinct environments on the same machine.