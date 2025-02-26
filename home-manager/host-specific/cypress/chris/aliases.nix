{ 
  pkgs,
  config,
  ... 
}: 

{

  programs.zsh = {
    shellAliases = {
      storage = "cd ${config.drives.storageDrive1} ; ls";
    };
  };

}