{ 
  pkgs, 
  config
}:

pkgs.writeShellScriptBin "deployThinkpad" 
''
  # create a temporary directory
  temp=$(mktemp -d)
  
  # function to cleanup temporary directory on exit
  cleanup() {
    rm -rf "$temp"
  }
  trap cleanup EXIT
  
  # create the directory where sops expects to find the age host key
  install -d -m755 "$temp/etc/age"
  
  # decrypt private key from the password store and copy it to the temporary directory
  pass hosts/thinkpad/age/private > "$temp/etc/age/thinkpad-age.key"
  
  # set the correct permissions
  chmod 600 "$temp/etc/age/thinkpad-age.key"

  # move to correct directory to generate hardware-configuration.nix
  cd /home/chris/nixos-configs/hosts/thinkpad
  
  # install
  nix run github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
  --extra-files "$temp" --disk-encryption-keys /tmp/crypt-passwd.txt <(pass /hosts/thinkpad/crypt-passwd) \
  --flake '.#thinkpad' nixos@192.168.1.62
''