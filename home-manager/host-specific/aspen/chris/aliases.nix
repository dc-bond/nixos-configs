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
      storage = "cd /storage/WD-WCC7K4RU947F ; ls";
      flakeupdate = "sudo nix flake update --flake ~/nixos-configs";
    };
  };

}