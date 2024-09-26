{ 
  inputs, 
  config, 
  ... 
}: 

{

  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];
  
  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    validateSopsFiles = false;
    age = {
      sshKeyPaths = [ 
        "/etc/ssh/ssh_host_ed25519_key" 
      ];
    };
    defaultSymlinkPath = "/run/user/1000/secrets";
    defaultSecretsMountPoint = "/run/user/1000/secrets.d";
  };

}