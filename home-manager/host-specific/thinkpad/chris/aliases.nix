{ 
  pkgs, 
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rbthink = "rebuildLocalThinkpad";
      rbcypress = "rebuildRemotecypress";
      rbaspen = "rebuildRemoteAspen";
      getnets = "iwctl station wlan0 get-networks";
      flakeupdate = "sudo nix flake update ~/nixos-configs";
    };
  };

}