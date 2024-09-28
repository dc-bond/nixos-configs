{ 
  inputs, 
  config, 
  ... 
}: 

{

  imports = [
    inputs.sops-nix.nixosModules.sops
  ];
  
  sops = {
    defaultSopsFile = ../../../secrets.yaml;
    defaultSopsFormat = "yaml";
    validateSopsFiles = false;
    gnupg = {
      sshKeyPaths = [];
    };
    age = {
      sshKeyPaths = [];
      #sshKeyPaths = [ 
      #  "/etc/ssh/ssh_host_ed25519_key" 
      #];
      #generateKey = false; # automatically generate age keypair if doesn't exist in above location
      keyFile = "/sops/thinkpad-keys.txt"; # sops/age will use private age key in this location to decrypt secrets.yaml that had previously been encrypted with age using its corresponding public age key
    };
    secrets = { # output to /run/secrets/...
      test = {};
      #opticonUrl = {};
      #opticonSshPort = {};
    };
  };

}