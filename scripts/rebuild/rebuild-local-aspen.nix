{ 
  pkgs, 
  config 
}:

let

  HOST = "aspen";
  
  rebuildLocalAspenScript = pkgs.writeShellScriptBin "rebuildLocalAspen" ''
  nixos_old_gen=$(readlink -f /run/current-system)
  sudo nixos-rebuild switch --flake ~/nixos-configs#${HOST}
  nixos_new_gen=$(readlink -f /run/current-system)
  nvd diff "$nixos_old_gen" "$nixos_new_gen"
  '';

in

{

  environment.systemPackages = with pkgs; [ 
    rebuildLocalAspenScript
  ];

}