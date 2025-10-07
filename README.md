<a href="https://nixos.org/">
  <img width="101" height="20" alt="NixOS" src="https://github.com/user-attachments/assets/100e6b95-643d-40f1-87ed-ccb214c61015" />
</a>

This repository contains the entire declarative configuration for my NixOS linux operating systems.

## Highlights

- ❄️ Nix flakes handle upstream dependencies and track latest stable release of Nixpkgs (currently 25.05)
- 🏠 [home-manager](https://github.com/nix-community/home-manager) manages dotfiles
- 🤫 [sops-nix](https://github.com/Mic92/sops-nix) manages secrets
- 🔒 Automatic Let's Encrypt certificate registration and renewal
- ☁️ Nextcloud, Jellyfin, Authelia, Matrix-Synapse, Tailscale, etc., among other self-hosted applications
- 🧩 Modular architecture facilitates quick deployment of services to different hosts
