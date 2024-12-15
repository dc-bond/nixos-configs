{ 
  pkgs,
  config
}:

let
  host = cypress;
in

pkgs.writeShellScriptBin "setup-borg-sshkeys" 
''
  ssh-keygen -N \"\" -t ed25519 -f /home/chris/borg-ed25519-${host}
  rsync borg-ed25519-${host} ssh cypress-tailscale:/tmp  
  ssh ${host}-tailscale "sudo mv /tmp/borg-ed25519-${host} /root/.ssh/"
  ssh ${host}-tailscale "sudo chmod 600 /root/.ssh/borg-ed25519-${host}"
  ssh ${host}-tailscale "sudo chown root:root /root/.ssh/borg-ed25519-${host}"
  cat /home/chris/borg-ed25519-${host}.pub
''
 
# rm -rf /home/chris/borg-ed25519-${host} /home/chris/borg-ed25519-${host}.pub