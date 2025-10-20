{ 
  config, 
  lib, 
  pkgs, 
  ... 
}: 

{

  programs.chromium = {
    enable = true;
    enablePlasmaBrowserIntegration = true;
    plasmaBrowserIntegrationPackage = pkgs.kdePackages.plasma-browser-integration;
    defaultSearchProviderEnabled = true;
    defaultSearchProviderSearchURL = "https://search.opticon.dev/?q={searchTerms}"
  };

}