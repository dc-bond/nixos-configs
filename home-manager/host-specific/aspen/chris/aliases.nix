{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rb = "rebuildLocalAspen";
      rbthink = "rebuildRemoteThinkpad";
      rbcypress = "rebuildRemoteCypress";
      storage = "cd /storage/WD-WCC7K4RU947F ; ls";
      flakeupdate = "sudo nix flake update --flake ~/nixos-configs";
      ledger = "cd /home/chris/nextcloud-client/Bond\\ Family/Financial/bond-ledger/ && nix develop";
    };
  };

}