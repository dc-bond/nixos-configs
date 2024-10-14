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
      home = "~/.gnupg";
      sshKeyPaths = [];
    };
    age = {
      sshKeyPaths = [];
    };
    defaultSymlinkPath = "/run/user/1000/secrets";
    defaultSecretsMountPoint = "/run/user/1000/secrets.d";
    secrets = {
      homeTest = {};
    };
  };

}