{ 
  pkgs, 
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rbthink = "rebuildLocalThinkpad";
      rbvm1 = "rebuildRemoteVm1";
      rbaspen = "rebuildRemoteAspen";
      getnets = "iwctl station wlan0 get-networks";
      flakeupdate = "sudo nix flake update ~/nixos-configs";
    };
  };

}