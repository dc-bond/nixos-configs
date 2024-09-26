{ 
  outputs, 
  pkgs, 
  config, 
  ... 
}: 

{

  nixpkgs = {
    overlays = [
      outputs.overlays.unstable-packages # import nixpkgs-unstable overlay
    ];
    config = {
      allowUnfree = true; # allow packages marked as proprietary/unfree
      allowBroken = false; # do not allow packages marked as broken
    };
  };

}