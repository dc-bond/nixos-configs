{ 
  pkgs,
  config,
  #configVars,
  ...
}:

# check ip on installation iso, set root password on installation iso with 'sudo passwd'

let
  host = "aspen";
  ipv4 = "192.168.1.189";
  #ipv4 = "${configVars.aspenLanIp}; # need to figure out how to get working
in

pkgs.writeShellScriptBin "deploy-${host}" 
''
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
  pass hosts/${host}/age/private > "$temp/etc/age/${host}-age.key"
  
  # set the correct permissions
  chmod 600 "$temp/etc/age/${host}-age.key"

  # move to correct directory to generate hardware-configuration.nix
  cd /home/chris/nixos-configs/hosts/${host}

  # install
  nix run github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
  --extra-files "$temp" \
  --flake '.#${host}' \
  root@${ipv4}
''