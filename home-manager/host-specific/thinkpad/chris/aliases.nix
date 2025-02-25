{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rbthink = "rebuildLocalThinkpad";
      rbcyp = "rebuildRemoteCypress";
      rbasp = "rebuildRemoteAspen";
      getnets = "iwctl station wlan0 get-networks";
      flakeupdate = "sudo nix flake update --flake ~/nixos-configs";
    };
  };

}