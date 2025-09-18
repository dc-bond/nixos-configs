{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rb = "nix flake update github:dc-bond/nixos-configs &&sudo nixos-rebuild switch --flake github:dc-bond/nixos-configs#juniper";
    };
  };

}