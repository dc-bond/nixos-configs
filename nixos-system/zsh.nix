{ 
  pkgs, 
  ... 
}: 

{

  programs.zsh = {
    enable = true; # z-shell enabled system-wide to source necessary files for users
    interactiveShellInit = '' 
      jlog() {
        journalctl -e -u "$1" --since "''${2:-1 day ago}" --no-pager --follow
      }
    ''; # function to tail systemd logs
  };
  
  environment.pathsToLink = [ "/share/zsh" ]; # to enable z-shell completion for system packages like systemd if using the zsh.nix home-manager module

}