{ 
  inputs, 
  config, 
  configLib,
  configVars,
  ... 
}: 

{

  imports = [
    inputs.sops-nix.nixosModules.sops
  ];
  
  home-manager.sharedModules = [
    inputs.sops-nix.homeManagerModules.sops # also import home-manager sops module so user level secrets also work
  ];

  sops = {
    defaultSopsFile = configLib.relativeToRoot "hosts/${config.networking.hostName}/secrets.yaml";
    defaultSopsFormat = "yaml";
    validateSopsFiles = false;
    gnupg = {
      sshKeyPaths = [];
    };
    age = {
      sshKeyPaths = [];
      keyFile = "/etc/age/${config.networking.hostName}-age.key"; # sops/age will use private age key in this location to decrypt secrets.yaml
    };
  };

}