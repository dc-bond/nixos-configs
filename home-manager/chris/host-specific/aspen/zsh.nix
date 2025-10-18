{ 
  config, 
  lib, 
  pkgs, 
  ... 
}: 

{
  
  programs.zsh = {
    shellAliases = {
      storage = "cd /storage/WD-WCC7K4RU947F ; ls";
    };
  };

}