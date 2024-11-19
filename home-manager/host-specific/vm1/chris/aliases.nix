{ 
  pkgs, 
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rbvm1 = "rebuildLocalVm1";
    };
  };

}