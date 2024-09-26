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
    defaultSopsFile = ../../../secrets.yaml;
    defaultSopsFormat = "yaml";
    validateSopsFiles = false;
  };

}