{ 
  pkgs,
  config,
  ...
}:

# check ip on installation iso, set root password on installation iso with 'sudo passwd'

let

  HOST = "thinkpad";
  IPV4 = "192.168.1.62";
  USER1 = "chris";
  
  deployThinkpadScript = pkgs.writeShellScriptBin "deployThinkpad" ''
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

    # create directory where sops expects to find age user key
    install -d -m700 "$temp/home/${USER1}/.config/age"
    
    # decrypt private user key from password store and copy to temp directory
    pass users/${USER1}/age/private > "$temp/home/${USER1}/.config/age/${USER1}-age.key"
    chmod 600 "$temp/home/${USER1}/.config/age/${USER1}-age.key"

    # move to correct directory to generate hardware-configuration.nix
    cd /home/${USER1}/nixos-configs/hosts/${HOST}

    # install
    nix run github:nix-community/nixos-anywhere -- \
    --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
    --disk-encryption-keys /tmp/crypt-passwd.txt <(pass users/${USER1}/passwd) \
    --extra-files "$temp" \
    --flake '.#${HOST}' \
    root@${IPV4}
  '';

in

{

  environment.systemPackages = with pkgs; [ 
    deployThinkpadScript
  ];

}