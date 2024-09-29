{ 
  pkgs, 
  config
}:

pkgs.writeShellScriptBin "thinkpadDeploy" 
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
  
  # install
  nixos-anywhere --extra-files "$temp" --disk-encryption-keys /tmp/crypt-passwd.txt <(pass /hosts/thinkpad/crypt-passwd) --flake '.#thinkpad' root@yourip
''