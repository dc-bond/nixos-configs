{ 
  pkgs, 
  config 
}:

pkgs.writeShellScriptBin "vm1Rebuild" 
''
  nixos-rebuild \
  --flake ~/nixos-configs#vm1 \
  --target-host vm1 \
  --use-remote-sudo \
  switch
''
  #nixos_old_gen=$(readlink -f /run/current-system)
  #sudo nixos-rebuild switch --flake ~/nixos-configs#thinkpad
  #nixos_new_gen=$(readlink -f /run/current-system)
  #nvd diff "$nixos_old_gen" "$nixos_new_gen"