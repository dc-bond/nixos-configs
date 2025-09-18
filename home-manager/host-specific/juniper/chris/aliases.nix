{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rb = "nix flake update --flake github:dc-bond/nixos-configs && sudo nixos-rebuild switch --flake github:dc-bond/nixos-configs#juniper --no-write-lock-file";
    };
  };

}