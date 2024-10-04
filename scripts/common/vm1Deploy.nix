{ 
  pkgs,
  config
}:

pkgs.writeShellScriptBin "vm1Deploy" 
''
  # create a temporary directory
  temp=$(mktemp -d)
  
  # function to cleanup temporary directory on exit
  cleanup() {
    rm -rf "$temp"
  }
  trap cleanup EXIT
  
  # create the directories where sops expects to find the age host key and chris ssh key
  install -d -m755 "$temp/etc/age"
  install -d -m755 "$temp2/home/chris/.ssh"
  
  # decrypt private key from the password store and copy it to the temporary directory
  pass hosts/thinkpad/age/private > "$temp/etc/age/vm1-age.key"
  cat /home/chris/.ssh/chris@vm1.key > "$temp2/home/chris/.ssh/chris@vm1.key"
  
  # set the correct permissions
  chmod 600 "$temp/etc/age/vm1-age.key"
  chmod 600 "$temp2/home/chris/.ssh/chris@vm1.key"

  # move to correct directory to generate hardware-configuration.nix
  cd /home/chris/nixos-configs/hosts/vm1

  # install
  nix run github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
  --extra-files "$temp" "$temp2" --disk-encryption-keys /tmp/crypt-passwd.txt <(pass /hosts/vm1/crypt-passwd) \
  --flake '.#vm1' nixos@192.168.1.237
''