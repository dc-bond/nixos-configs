{ 
  pkgs, 
  ... 
}: 

{

  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  programs.xfconf.enable = true; # enable xfconf to save preferences in thuar

  services.gvfs.enable = true; # mount, trash, and other functionalities

  services.tumbler.enable = true; # thumbnail support for images

}