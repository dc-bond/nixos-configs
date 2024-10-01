{ 
  inputs, 
  config, 
  ... 
}: 

#let
#  secretsPath = builtins.toString inputs.nixos-secrets;
#in

{

  imports = [
    inputs.sops-nix.nixosModules.sops
  ];
  
  sops = {
    #defaultSopsFile = "${secretsPath}/secrets.yaml";
    defaultSopsFile = ../../../secrets.yaml;
    defaultSopsFormat = "yaml";
    validateSopsFiles = false;
    gnupg = {
      sshKeyPaths = [];
    };
    age = {
      sshKeyPaths = [];
      keyFile = "/etc/age/thinkpad-age.key"; # sops/age will use private age key in this location to decrypt secrets.yaml that had previously been encrypted with age using its corresponding public age key
    };
    secrets = { # output to /run/secrets/...
      test = {};
      #opticonUrl = {};
      #opticonSshPort = {};
    };
  };

}