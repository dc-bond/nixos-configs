{ 
  pkgs, 
  config,
  configVars,
  lib,
  ... 
}: 

{

  environment = {
    systemPackages = with pkgs; [ 
      mangohud 
      protonup
    ];
    sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = 
        "/home/${configVars.chrisUsername}/.steam/root/compatibilitytools.d";
    };
  };

  programs = {
    steam = {
      enable = true;
    };
    gamemode.enable = true;
  };

}