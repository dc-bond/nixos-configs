{ 
  config, 
  lib,
  pkgs, 
  ... 
}: 

{

  programs.chromium = {
    enable = true;
    package = pkgs.pkgs-2505.chromium; # pinned to 25.05 because of cups printing bug in 25.11
    commandLineArgs = [
      "--enable-features=UseOzonePlatform"
      "--ozone-platform=wayland"
      "--enable-wayland-ime"
    ];
  };

}