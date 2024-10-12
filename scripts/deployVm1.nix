{ 
  pkgs,
  config
}:

pkgs.writeShellScriptBin "deployVm1" 
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
  pass hosts/thinkpad/age/private > "$temp/etc/age/vm1-age.key"
  
  # set the correct permissions
  chmod 600 "$temp/etc/age/vm1-age.key"

  # move to correct directory to generate hardware-configuration.nix
  cd /home/chris/nixos-configs/hosts/vm1

  # install
  nix run github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
  --extra-files "$temp" --disk-encryption-keys /tmp/crypt-passwd.txt <(pass /hosts/vm1/crypt-passwd) \
  --flake 'github:dc-bond/nixos-configs#vm1' nixos@192.168.1.199
''