{ 
  pkgs, 
  config 
}:

pkgs.writeShellScriptBin "rebuild-local-cypress" 
''
  nixos_old_gen=$(readlink -f /run/current-system)
  sudo nixos-rebuild switch --flake ~/nixos-configs#cypress
  nixos_new_gen=$(readlink -f /run/current-system)
  nvd diff "$nixos_old_gen" "$nixos_new_gen"
''