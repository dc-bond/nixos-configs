{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rbthink = "rebuild-local-thinkpad";
      rbcypress = "rebuild-remote-cypress";
      rbaspen = "rebuild-remote-aspen";
      getnets = "iwctl station wlan0 get-networks";
      flakeupdate = "sudo nix flake update --flake ~/nixos-configs";
    };
  };

}