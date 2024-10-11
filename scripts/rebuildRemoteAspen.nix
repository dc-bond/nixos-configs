{ 
  pkgs, 
  config 
}:

pkgs.writeShellScriptBin "rebuildRemoteAspen" 
''
  nixos_old_gen=$(ssh aspen 'readlink -f /run/current-system')
  nixos-rebuild \
  --flake ~/nixos-configs#aspen \
  --target-host aspen \
  --use-remote-sudo \
  --verbose \
  switch
  nixos_new_gen=$(ssh aspen 'readlink -f /run/current-system')
  nvd diff "$nixos_old_gen" "$nixos_new_gen"
''