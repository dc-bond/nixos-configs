{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rb = "nix flake update github:dc-bond/nixos-configs &&sudo nixos-rebuild switch --flake github:dc-bond/nixos-configs#aspen";
      storage = "cd /storage/WD-WCC7K4RU947F ; ls";
    };
  };

}