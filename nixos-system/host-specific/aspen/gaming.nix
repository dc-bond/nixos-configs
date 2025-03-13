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
      heroic
    ];
    sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = 
        "/home/${configVars.userName}/.steam/root/compatibilitytools.d";
    };
  };

  programs = {
    steam = {
      enable = true;
      gamescopeSession = {
        enable = true;
      };
    };
    gamemode.enable = true;
  };

}