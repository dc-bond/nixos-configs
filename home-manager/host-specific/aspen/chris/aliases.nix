{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rbasp = "rebuildLocalAspen";
      rbthink = "rebuildRemoteThinkpad";
      rbcyp = "rebuildRemoteCypress";
      flakeupdate = "sudo nix flake update --flake ~/nixos-configs";
    };
  };

}