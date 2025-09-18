{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rb = "sudo nixos-rebuild switch --flake github:dc-bond/nixos-configs#aspen";
      storage = "cd /storage/WD-WCC7K4RU947F ; ls";
    };
  };

}