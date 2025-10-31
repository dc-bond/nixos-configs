{ 
  inputs, 
  config, 
  configLib,
  configVars,
  pkgs,
  ... 
}: 

{

  environment.systemPackages = with pkgs; [ sops ];

  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = { # system-level sops configs
    defaultSopsFile = configLib.relativeToRoot "secrets.yaml";
    defaultSopsFormat = "yaml";
    validateSopsFiles = false;
    gnupg = {
      sshKeyPaths = [];
    };
    age = {
      sshKeyPaths = [];
      keyFile = "/etc/age/${config.networking.hostName}-age.key"; # sops/age will use private host age key in this location to decrypt secrets.yaml
    };
  };

  home-manager.sharedModules = [ inputs.sops-nix.homeManagerModules.sops ]; # import home-manager sops module so user level secrets also work

}