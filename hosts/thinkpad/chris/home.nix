{ 
  inputs, 
  config,
  lib,
  configLib,
  configVars,
  pkgs, 
  ... 
}: 

{
  
  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "home-manager/chris/common/zsh.nix"
      "home-manager/chris/common/starship.nix"
      "home-manager/chris/common/neovim.nix"
      "home-manager/chris/common/ssh.nix"
      "home-manager/chris/common/git.nix"
      "home-manager/chris/common/gnupg.nix"
      "home-manager/chris/common/pass.nix"
      
      "home-manager/chris/common/email.nix"

      #"home-manager/chris/host-specific/thinkpad/hyprland.nix"
      "home-manager/chris/host-specific/thinkpad/plasma.nix"
    ])
  ];

  home.packages = with pkgs; [
    (import (configLib.relativeToRoot "scripts/get-pass-repo.nix") { inherit pkgs config; })
  ];

  programs = {
    home-manager.enable = true; # enable home manager
    zsh = {
      shellAliases = {
        flakeupdate = "sudo nix flake update --flake ~/nixos-configs";
        getnets = "iwctl station wlan0 get-networks";
        ledger = "cd /home/chris/nextcloud-client/Bond\\ Family/Financial/bond-ledger/ && nix develop";
        speed = "nix run nixpkgs#speedtest-rs";
        tsaspen = "sudo tailscale down && sleep 5 && sudo tailscale up -ssh --accept-routes --exit-node=${configVars.aspenTailscaleIp}";
        tsjuniper = "sudo tailscale down && sleep 5 && sudo tailscale up -ssh --accept-routes --exit-node=${configVars.juniperTailscaleIp}";
      };
    };
  };

# define username and home directory
  home = {
    username = configVars.chrisUsername;
    homeDirectory = "/home/${configVars.chrisUsername}";
  };

# define default folders in home directory
  xdg.userDirs = {
    enable = true;
    download = "${config.home.homeDirectory}/downloads";
    desktop = null;
  };

# start/re-start services after system rebuild
  systemd.user.startServices = "sd-switch";

# original home state version - defines the first version of home-manager installed to maintain compatibility with application data (e.g. databases) created on older versions that can't automatically update their data when their package is updated
  home.stateVersion = "23.11";

}
