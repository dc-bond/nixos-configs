{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rbmain = "sudo nixos-rebuild switch --flake github:dc-bond/nixos-configs#$(hostname) --refresh";
      rbdev = "sudo nixos-rebuild switch --flake github:dc-bond/nixos-configs/dev#$(hostname) --refresh";
      garbage = "nix-collect-garbage -d && sudo nix-collect-garbage -d";
    };
  };

}