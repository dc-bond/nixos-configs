{ pkgs, config }:

pkgs.writeShellScriptBin "rebuild-diff" 
''
  nixos_old_gen=$(readlink -f /run/current-system)
  sudo nixos-rebuild switch --flake ~/nixos-configs
  nixos_new_gen=$(readlink -f /run/current-system)
  nvd "$nixos_old_gen" "$nixos_new_gen"
''