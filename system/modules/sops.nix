{ inputs, config, ... }: 

{

  imports = [
    inputs.sops-nix.nixosModules.sops
  ];
  
  sops = {
    defaultSopsFile = ../../secrets.yaml;
    defaultSopsFormat = "yaml";
    validateSopsFiles = false;
    gnupg = {
      home = "~/.gnupg";
      sshKeyPaths = [ ];
    };
    age = { # sops will use host's ssh key to derive a private age key to decrypt secrets.yaml that had previously been encrypted using same ssh key's derived age public key
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]; # path to SSH public key that should be used to derive age keys
      #keyFile = "/var/lib/sops-nix/key.txt"; # where age key lives in the file system
      #generateKey = true; # automatically generate age keypair if doesn't exist in above location
    };
    secrets = { # output to /run/secrets/...
      sshd-port = {};
      test = {};
    };
  };

}