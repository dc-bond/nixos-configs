{ 
  pkgs,
  config,
  ...
}:

# check ip on installation iso, set root password on installation iso with 'sudo passwd'

let

  HOST = "alder";
  IPV4 = "192.168.4.15";
  USER1 = "chris";
  USER2 = "eric";
  
  deployAlderScript = pkgs.writeShellScriptBin "deployAlder" ''
    #!/usr/bin/env bash

    # create a temporary directory
    temp=$(mktemp -d)
    
    # function to cleanup temporary directory on exit
    cleanup() {
      rm -rf "$temp"
    }
    trap cleanup EXIT
    
    # create directory where sops expects to find the age host key
    install -d -m755 "$temp/etc/age"
    
    # decrypt private system key from password store and copy to temp directory
    pass hosts/${HOST}/age/private > "$temp/etc/age/${HOST}-age.key"
    
    # set the correct permissions
    chmod 600 "$temp/etc/age/${HOST}-age.key"
    
    # create directories where sops expects to find age user keys
    install -d -m700 "$temp/home/${USER1}/.config/age"
    install -d -m700 "$temp/home/${USER2}/.config/age"
    
    # decrypt private user keys from password store and copy to temp directory
    pass users/${USER1}/age/private > "$temp/home/${USER1}/.config/age/${USER1}-age.key"
    chmod 600 "$temp/home/${USER1}/.config/age/${USER1}-age.key"
    pass users/${USER2}/age/private > "$temp/home/${USER2}/.config/age/${USER2}-age.key"
    chmod 600 "$temp/home/${USER2}/.config/age/${USER2}-age.key"
    
    # get UIDs from the flake configuration
    CHRIS_UID=$(nix eval --raw ".#nixosConfigurations.${HOST}.config.users.users.${USER1}.uid")
    ERIC_UID=$(nix eval --raw ".#nixosConfigurations.${HOST}.config.users.users.${USER2}.uid")
    
    # move to correct directory to generate hardware-configuration.nix
    cd /home/${USER1}/nixos-configs/hosts/${HOST}
    
    # install with proper ownership
    nix run github:nix-community/nixos-anywhere -- \
      --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
      --disk-encryption-keys /tmp/crypt-passwd.txt <(pass users/${USER2}/passwd) \
      --extra-files "$temp" \
      --chown /home/${USER1} ${CHRIS_UID}:100 \
      --chown /home/${USER2} ${ERIC_UID}:100 \
      --flake '.#${HOST}' \
      root@${IPV4}
  '';

in

{

  environment.systemPackages = with pkgs; [ 
    deployAlderScript
  ];

}