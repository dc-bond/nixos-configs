{ 
  pkgs,
  config
}:

let
  host = "cypress";
in

pkgs.writeShellScriptBin "setup-borg-sshkeys" 
''
  ssh-keygen -N "" -t ed25519 -f /home/chris/borg-ed25519-${host}
  rsync --progress -avzh /home/chris/borg-ed25519-${host} ${host}-tailscale:/tmp  
  ssh ${host}-tailscale "sudo mv /tmp/borg-ed25519-${host} /root/.ssh/"
  ssh ${host}-tailscale "sudo chmod 600 /root/.ssh/borg-ed25519-${host}"
  ssh ${host}-tailscale "sudo chown root:root /root/.ssh/borg-ed25519-${host}"
  echo ""
  echo ""
  echo "REMEMBER TO COPY PUBKEY INTO authorizedKeys SECTION IN BORG.NIX MODULE FOR REPO HOST THEN REBUILD"
  echo ""
  echo ""
  cat /home/chris/borg-ed25519-${host}.pub
  rm -rf /home/chris/borg-ed25519-${host} /home/chris/borg-ed25519-${host}.pub
''