{ inputs, config, ... }: 

{

  imports = [
    inputs.hyprland.nixosModules.default
  ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true; # defaults to true
  };

}