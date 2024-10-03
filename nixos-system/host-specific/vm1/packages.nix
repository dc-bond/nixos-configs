{ 
  pkgs, 
  configLib,
  ... 
}: 

{

  environment.systemPackages = with pkgs; [
    (import (configLib.relativeToRoot "scripts/host-specific/vm1/rebuild.nix") { inherit pkgs config; })
  ];

}