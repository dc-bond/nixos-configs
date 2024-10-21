{ 
  pkgs,
  config
}:

let
  host = "aspen";
  ipv4 = "172.104.11.196";
in

pkgs.writeShellScriptBin "deploy-${host}" 
''
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