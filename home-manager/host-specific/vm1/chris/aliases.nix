{ 
  pkgs, 
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      rbldloc = "rebuildLocalVm1";
    };
  };

}