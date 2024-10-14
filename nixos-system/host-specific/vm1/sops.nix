{ 
  inputs, 
  config, 
  configLib,
  ... 
}: 

{

  imports = [
    inputs.sops-nix.nixosModules.sops
  ];
  
  sops = {
    defaultSopsFile = configLib.relativeToRoot "hosts/vm1/secrets.yaml";
    defaultSopsFormat = "yaml";
    validateSopsFiles = false;
    gnupg = {
      sshKeyPaths = [];
    };
    age = {
      sshKeyPaths = [];
      keyFile = "/etc/age/vm1-age.key"; # sops/age will use private age key in this location to decrypt secrets.yaml
    };
    secrets = { # output to /run/secrets/...
      test = {};
    };
  };

}