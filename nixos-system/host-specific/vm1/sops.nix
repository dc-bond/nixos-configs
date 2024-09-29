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
      keyFile = "/etc/age/vm1-age.key"; # sops/age will use private age key in this location to decrypt secrets.yaml that had previously been encrypted with age using its corresponding public age key
    };
    secrets = { # output to /run/secrets/...
      test = {};
      #opticonUrl = {};
      #opticonSshPort = {};
    };
  };

}