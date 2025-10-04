{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rb = "sudo nixos-rebuild switch --flake github:dc-bond/nixos-configs#juniper --refresh";
      garbage = "nix-collect-garbage -d && sudo nix-collect-garbage -d";
    };
  };

}