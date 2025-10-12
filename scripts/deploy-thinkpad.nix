{ 
  pkgs,
  config,
  ...
}:

# check ip on installation iso, set root password on installation iso with 'sudo passwd'

let

  HOST = "thinkpad";
  IPV4 = "192.168.1.62";
  
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
    
    # decrypt private key from the password store and copy it to the temporary directory
    pass hosts/${HOST}/age/private > "$temp/etc/age/${HOST}-age.key"
    
    # set the correct permissions
    chmod 600 "$temp/etc/age/${HOST}-age.key"

    # move to correct directory to generate hardware-configuration.nix
    cd /home/chris/nixos-configs/hosts/${HOST}

    # install
    nix run github:nix-community/nixos-anywhere -- \
    --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
    --disk-encryption-keys /tmp/crypt-passwd.txt <(pass hosts/${HOST}/crypt-passwd) \
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