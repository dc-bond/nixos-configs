{ 
  pkgs, 
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      networks = "iwctl station wlan0 get-networks";
    };
  };

}