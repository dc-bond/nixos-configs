{ 
  pkgs, 
  config,
  ...
}:

let

  rebuildHostScript = pkgs.writeShellScriptBin "rebuildHost" ''
    # define available hosts
    HOSTS=("aspen", "cypress" "thinkpad")
    
    # display menu options for hosts
    echo "Select host to rebuild:"
    for i in "''${!HOSTS[@]}"; do
      echo "$((i+1))) ''${HOSTS[$i]}"
    done
    
    # obtain target host from user
    read -p "Enter host number: " CHOICE
    
    # validate host selection
    if [[ ! "$CHOICE" =~ ^[1-3]$ ]]; then
      echo "Error: Invalid selection."
      exit 1
    fi
    
    # set the selected host
    HOST="''${HOSTS[$((CHOICE-1))]}"

    nixos_old_gen=$(ssh $HOST 'readlink -f /run/current-system')
    nixos-rebuild \
    --flake ~/nixos-configs#$HOST \
    --target-host $HOST \
    --use-remote-sudo \
    --verbose \
    switch
    nixos_new_gen=$(ssh $HOST 'readlink -f /run/current-system')
    nvd diff "$nixos_old_gen" "$nixos_new_gen"
  '';

in

{

  environment.systemPackages = with pkgs; [ 
    rebuildHostScript
  ];

}  