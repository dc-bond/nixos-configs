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
    #secrets = { # output to /run/secrets/...
    #  test = {};
    #  homeTest = {
    #    owner = "${config.users.users.${configVars.userName}.name}";
    #    group = "${config.users.users.${configVars.userName}.group}";
    #    mode = "0440";
    #  };
    #};
  };

}