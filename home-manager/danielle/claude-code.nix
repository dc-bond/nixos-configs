{
  pkgs,
  lib,
  ...
}:

{

  programs.claude-code = {
    enable = true;
    package = pkgs.unstable.claude-code; # pinned to unstable for parity with the VSCodium extension (see DEVIATIONS.md)

    # MCP servers are baked into a wrapped `claude` binary via `--mcp-config`.
    # mcp-nixos serves live NixOS/Home Manager package + option data over stdio.
    # Referenced by store path, so it needs no separate home.packages entry.
    mcpServers.nixos = {
      type = "stdio";
      command = lib.getExe pkgs.unstable.mcp-nixos; # 25.11 ships only 1.0.3; unstable for the 2.x tool surface (see DEVIATIONS.md)
    };

    # Declarative ~/.claude/settings.json — home-manager symlinks it read-only into
    # the store (replaces the former seed-once home.activation approach), so it is
    # dropped from kauri impermanence. Runtime state (trust, "always allow" grants,
    # project MCP registrations) still lives in the writable ~/.claude.json, which
    # impermanence persists separately.
    settings = {
      permissions.deny = [
        "Bash(nixos-rebuild *)"
        "Bash(sudo nixos-rebuild *)"
        "Bash(nix build *)"
        "Bash(sudo nix build *)"
        "Bash(nix-collect-garbage *)"
        "Bash(sudo nix-collect-garbage *)"
      ];
      model = "sonnet";
      theme = "dark";
      tui = "fullscreen";
    };
  };

}
