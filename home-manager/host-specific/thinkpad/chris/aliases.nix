{ 
  pkgs, 
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rbthink = "rebuild-local-thinkpad";
      rbcypress = "rebuildRemotecypress";
      rbaspen = "rebuild-remote-aspen";
      getnets = "iwctl station wlan0 get-networks";
      flakeupdate = "sudo nix flake update --flake --verbose ~/nixos-configs";
    };
  };

}