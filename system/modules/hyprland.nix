{ 
pkgs,
#inputs, 
#config, 
... 
}: 

{

  programs.hyprland = {
    enable = true;
    package = pkgs.unstable.hyprland;
  };

}

  #imports = [
  #  inputs.hyprland.nixosModules.default # imported from flake inputs
  #];