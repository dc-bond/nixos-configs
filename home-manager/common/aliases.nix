{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rbtest = "sudo nixos-rebuild switch --flake github:dc-bond/nixos-configs/testing#$(hostname) --refresh";
      rbmain = "sudo nixos-rebuild switch --flake github:dc-bond/nixos-configs#$(hostname) --refresh";
      garbage = "nix-collect-garbage -d && sudo nix-collect-garbage -d";
    };
  };

}