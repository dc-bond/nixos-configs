{ 
  inputs, 
  config, 
  configLib,
  ... 
}: 

{

  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];
  
  sops = {
    defaultSopsFile = configLib.relativeToRoot "secrets.yaml";
    defaultSopsFormat = "yaml";
    validateSopsFiles = false;
    gnupg = {
      sshKeyPaths = [];
    };
    age = {
      sshKeyPaths = [];
      keyFile = "/etc/age/thinkpad-age.key"; # sops/age will use private age key in this location to decrypt secrets.yaml
    };
    defaultSymlinkPath = "/run/user/1000/secrets";
    defaultSecretsMountPoint = "/run/user/1000/secrets.d";
    secrets = {
      test2 = {};
    };
  };

}