{ 
  pkgs, 
  ... 
}: 

{

  programs.zsh.enable = true; # z-shell enabled system-wide to source necessary files for users
  
  environment.pathsToLink = [ "/share/zsh" ]; # to enable z-shell completion for system packages like systemd if using the zsh.nix home-manager module

}