{ 
  pkgs, 
  config,
  lib,
  ... 
}: 

{

  sops.secrets = {
    tailscaleAuthKey = {};
  };

  networking.firewall = {
    #checkReversePath = "loose";
    trustedInterfaces = [
      "tailscale0"
    ];
  };

  services = {
    tailscale = {
      enable = true;
      authKeyFile = "${config.sops.secrets.tailscaleAuthKey.path}";
      useRoutingFeatures = "client";
      extraUpFlags = [
        #"--accept-dns=false" # disable magic DNS
        "--accept-routes" # autmatically accept subnet routes advertised by other nodes
      ];
      extraSetFlags = [
        #"--exit-node=100.92.225.78"
        "--exit-node=opticon"
        "--exit-node-allow-lan-access=true"
      ];
    };
  };

}