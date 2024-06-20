{ inputs, config, ... }: 

{

  imports = [
    inputs.sops-nix.nixosModules.sops
  ];
  
  sops = {
    defaultSopsFile = ./secrets.sops.yaml ;
    validateSopsFiles = false;
    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]; # path to SSH public key that should be used to derive age keys
      keyFile = "/var/lib/sops-nix/key.txt"; # path where derived age private key is expected to live
      generateKey = true; # automatically derive age private key if doesn't exist in above location
    };
  };

}