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
    package = pkgs.hyprland;
  };

}