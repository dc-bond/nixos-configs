{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      storage = "cd /storage/WD-WX21DC86RU3P ; ls";
      garbage = "nix-collect-garbage -d && sudo nix-collect-garbage -d";
    };
  };

}