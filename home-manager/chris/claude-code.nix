{
  pkgs,
  lib,
  ...
}:

{

  programs.claude-code = {
    enable = true;
    package = pkgs.unstable.claude-code; # pinned to unstable for parity with the VSCodium extension (see DEVIATIONS.md)
    mcpServers.nixos = {
      type = "stdio";
      command = lib.getExe pkgs.unstable.mcp-nixos; # 25.11 ships only 1.0.3; unstable for the 2.x tool surface (see DEVIATIONS.md)
    };
    settings = {
      permissions = {
        allow = [
          "Bash(nix eval *)"
          "Bash(nix-instantiate --parse *)"
          "Bash(nix-instantiate --eval *)"
          "Bash(nix-shell -p *)"
          "Bash(nix shell nixpkgs#*)"
          "Bash(tailscale status *)"
        ];
        deny = [
          "Bash(nixos-rebuild *)"
          "Bash(sudo nixos-rebuild *)"
          "Bash(nix build *)"
          "Bash(sudo nix build *)"
          "Bash(nix-collect-garbage *)"
          "Bash(sudo nix-collect-garbage *)"
        ];
        defaultMode = "auto";
      };
      enabledMcpjsonServers = [ "nixos" ]; # pre-approve the mcp-nixos server in ~/nixos/.mcp.json (see zsh.nix clone-configs)
      effortLevel = "high";
      theme = "dark";
      autoMode.environment = [
        "$defaults"
        "Organization: chris's personal homelab and household — a single operator (chris, chris@dcbond.com); no company, team, or shared tenancy. Claude runs only on his own workstations, thinkpad and cypress."
        "Primary use of Claude Code, in two modes signalled by the working directory and its CLAUDE.md: (1) from ~/nixos (a pointer directory holding two flakes cloned fresh each boot — the public nixos-configs and its private companion nixos-configs-private): Linux homelab infrastructure-as-code in Nix plus routine maintenance and read-only diagnostics; (2) from folders under ~/nextcloud-client and similar, each with its own CLAUDE.md: general office/administrative help across broad personal and family subject matter — drafting documents and spreadsheets, generating and OCRing PDFs, and the like. Generating files locally with tools such as pandoc, tesseract, and poppler/pdf utilities inside the working directory is routine expected work."
        "Cloud provider(s): self-hosted homelab on bare-metal servers plus one VPS (juniper); off-site backups go to Backblaze B2 via rclone. No corporate cloud accounts."
        "Source control: github.com/dc-bond and all repos under it — a personal GitHub account, not an org — notably nixos-configs and the private nixos-configs-private flake it pulls over git+ssh. Committing and pushing to these is routine internal work."
        "Trusted internal domains: *.opticon.dev and *.dcbond.com — the operator's own self-hosted services behind Traefik, reachable on the LAN and over the Tailscale tailnet — plus the tailnet hosts aspen, juniper, kauri, cypress, thinkpad. These are his own infrastructure; reaching them, including read-only SSH diagnostics, is internal, not an external destination."
        "Key internal services (self-hosted on the domains above, administered read-only over Tailscale SSH): Nextcloud (file storage/sync), Vaultwarden, Home Assistant, Pi-hole + Unbound DNS, Prometheus/Grafana/Alertmanager, Traefik, Authelia + LLDAP SSO, Jellyfin and the *arr media stack. There is no private package registry — Nix pulls from nixpkgs and flake inputs."
        "Sensitive data locations & audiences: everything under ~/nextcloud-client and its Nextcloud counterpart (personal and family financial, housing/lease, insurance, and personal records) is personal/entrusted data. Cleared audience: chris, his household, and his own self-hosted services (this data already lives in his Nextcloud). Copying or sending it anywhere else — external email, third-party sites, public repos, pastes, arbitrary web endpoints — is out-of-place egress, even though he sometimes hand-delivers a drafted document to a specific outside party himself."
        "Additional context — standing operator preferences (he approves most prompts and wants routine work uninterrupted, but wants these kept gated): he performs ALL system rebuilds/activations and remote state changes himself — nixos-rebuild, nix builds, garbage collection, and service restarts/deploys on the servers (rebuild/build/GC are also hard-denied); Claude edits configuration and runs read-only diagnostics only. Apply the ordinary Linux-sysadmin/developer red lines otherwise: gate irreversible or bulk file deletion, destructive disk/filesystem operations, credential/secret exposure, rerouting package installs, force-pushing or rewriting shared git history, and the personal-data egress above."
      ];
      tui = "fullscreen";
      model = "opus";
    };
  };

}