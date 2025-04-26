{
  inputs, 
  ...
}: 

builtins.mapAttrsToList
  (name: _: import (./. + "/${name}") { inherit inputs; })
  (builtins.removeAttrs (builtins.readDir ./.) [ "default.nix" ])