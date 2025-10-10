{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rbtest = "sudo nixos-rebuild switch --flake github:dc-bond/nixos-configs/testing#${config.networking.hostName} --refresh";
      rbmain = "sudo nixos-rebuild switch --flake github:dc-bond/nixos-configs#${config.networking.hostName} --refresh";
      garbage = "nix-collect-garbage -d && sudo nix-collect-garbage -d";
    };
  };

}