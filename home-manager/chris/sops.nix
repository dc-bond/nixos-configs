{ 
  config, 
  configLib,
  configVars,
  ... 
}: 

{

  sops = { # home-manager level sops config for specific user
    defaultSopsFile = configLib.relativeToRoot "secrets.yaml";
    defaultSopsFormat = "yaml";
    validateSopsFiles = false;
    gnupg = {
      sshKeyPaths = [];
    };
    age = {
      sshKeyPaths = [];
      keyFile = "${config.home.homeDirectory}/.config/age/${configVars.chrisUsername}-age.key"; # sops/age will use private user age key in this location to decrypt secrets.yaml
    };
  };

}