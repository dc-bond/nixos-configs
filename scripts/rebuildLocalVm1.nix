{ 
  pkgs, 
  config 
}:

pkgs.writeShellScriptBin "rebuildLocalVm1" 
''
  nixos_old_gen=$(readlink -f /run/current-system)
  sudo nixos-rebuild switch --flake ~/nixos-configs#vm1
  nixos_new_gen=$(readlink -f /run/current-system)
  nvd diff "$nixos_old_gen" "$nixos_new_gen"
''