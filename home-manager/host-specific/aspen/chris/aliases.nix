{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rbaspen = "rebuildLocalAspen";
      rbthink = "rebuildRemoteThinkpad";
      rbcypress = "rebuildRemoteCypress";
      flakeupdate = "sudo nix flake update --flake ~/nixos-configs";
    };
  };

}