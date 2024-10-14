{ 
  inputs, 
  config, 
  configLib,
  ... 
}: 

{

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
    defaultSymlinkPath = "/run/user/1000/secrets";
    defaultSecretsMountPoint = "/run/user/1000/secrets.d";
    secrets = {
      homeTest = {};
    };
  };

}