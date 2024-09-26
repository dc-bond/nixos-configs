{ 
pkgs,
#inputs, 
#config, 
... 
}: 

{

  environment.systemPackages = with pkgs; [
    hyprshot # screenshot tool
  ];

  programs.hyprland = {
    enable = true;
    package = pkgs.unstable.hyprland;
  };

}

  #imports = [
  #  inputs.hyprland.nixosModules.default # imported from flake inputs
  #];