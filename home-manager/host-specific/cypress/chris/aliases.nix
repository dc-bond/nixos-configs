{ 
  pkgs, 
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rbcypress = "rebuild-local-cypress";
    };
  };

}