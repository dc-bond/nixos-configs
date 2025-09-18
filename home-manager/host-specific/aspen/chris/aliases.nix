{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rb = "nix flake update --flake github:dc-bond/nixos-configs && sudo nixos-rebuild switch --flake github:dc-bond/nixos-configs#aspen --no-write-lock-file";
      storage = "cd /storage/WD-WCC7K4RU947F ; ls";
    };
  };

}