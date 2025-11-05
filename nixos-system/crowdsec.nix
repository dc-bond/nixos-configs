{ 
  pkgs, 
  ... 
}: 

{

  imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/security/crowdsec.nix" ];

  services.crowdsec = {
    enable = true;
  };

}