{ 
  inputs, 
  config,
  lib,
  configLib,
  configVars,
  pkgs, 
  ... 
}:

let
  username = builtins.baseNameOf ./.;
  claudeSettings = pkgs.writeText "claude-settings.json" (builtins.toJSON {
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
  });
in

{
  
  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "home-manager/shared/sops.nix"
      "home-manager/shared/starship.nix"
      "home-manager/shared/neovim.nix"
      "home-manager/shared/zsh.nix"
      "home-manager/shared/wayvnc.nix"
      "home-manager/${username}/labwc.nix"
    ])
  ];

  programs.home-manager.enable = true; # enable home manager

# define username and home directory
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    packages = with pkgs; [
      brightnessctl # screen brightness control
      ddcutil # query and change monitor settings via DDC/CI (requires system hardware.i2c.enable)
      wlr-randr # wayland display configuration tool for wlroots compositors
      unstable.claude-code # claude code CLI (pinned to unstable for parity with vscodium extension)
    ];
  };

# seed claude code settings with sensible defaults on first run only, then leave user-editable (in-app /config writes must persist)
# guard on -s (non-empty), not -e: under impermanence the persisted settings.json is bind-mounted as an empty placeholder before activation, which must still be seeded
  home.activation.seedClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -s "$HOME/.claude/settings.json" ]; then
      run mkdir -p "$HOME/.claude"
      run cp ${claudeSettings} "$HOME/.claude/settings.json"
      run chmod 600 "$HOME/.claude/settings.json"
    fi
  '';

# define default folders in home directory
  xdg.userDirs = {
    enable = true;
    createDirectories = false;
    download = "${config.home.homeDirectory}/downloads";
    documents = "${config.home.homeDirectory}/documents";
    desktop = null;
  };
  
  # ensure nextcloud-client directory exists
  systemd.user.tmpfiles.rules = [
    "d %h/nextcloud-client 0755 - - -"
  ];

# start/re-start services after system rebuild
  systemd.user.startServices = "sd-switch";

# original home state version - defines the first version of home-manager installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  home.stateVersion = "25.11";

}
