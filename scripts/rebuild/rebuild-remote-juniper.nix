{ 
  pkgs, 
  config,
  ...
}:

let

  HOST = "juniper";
  
  rebuildRemoteJuniperScript = pkgs.writeShellScriptBin "rebuildRemoteJuniper" ''
    nixos_old_gen=$(ssh ${HOST} 'readlink -f /run/current-system')
    nixos-rebuild \
    --flake ~/nixos-configs#${HOST} \
    --target-host ${HOST} \
    --use-remote-sudo \
    --verbose \
    switch
    nixos_new_gen=$(ssh ${HOST} 'readlink -f /run/current-system')
    nvd diff "$nixos_old_gen" "$nixos_new_gen"
  '';

in

{

  environment.systemPackages = with pkgs; [ 
    rebuildRemoteJuniperScript
  ];

}  