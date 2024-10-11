{ 
  pkgs, 
  config 
}:

pkgs.writeShellScriptBin "rebuildRemoteVm1" 
''
  nixos_old_gen=$(ssh vm1 'readlink -f /run/current-system')
  nixos-rebuild \
  --flake ~/nixos-configs#vm1 \
  --target-host vm1 \
  --use-remote-sudo \
  --verbose \
  switch
  nixos_new_gen=$(ssh vm1 'readlink -f /run/current-system')
  nvd diff "$nixos_old_gen" "$nixos_new_gen"
''