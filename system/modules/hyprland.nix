{ inputs, config, ... }: 

{

  imports = [
    hyprland.nixosModules.default # imported from flake inputs
  ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true; # defaults to true
  };

}