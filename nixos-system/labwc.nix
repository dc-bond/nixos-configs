{ 
  pkgs,
  config,
  configVars,
  lib,
  ... 
}: 

{

  programs.labwc = {
    enable = true;
  };

}
