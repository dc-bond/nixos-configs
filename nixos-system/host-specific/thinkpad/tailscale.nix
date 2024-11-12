{ 
  pkgs, 
  config,
  ... 
}: 

{

  sops.secrets = {
    tailscaleAuthKey = {};
  };

  networking.firewall = {
    trustedInterfaces = [
      "tailscale0"
    ];
  };

  services.tailscale = {
    enable = true;
    authKeyFile = "${config.sops.secrets.tailscaleAuthKey.path}";
    useRoutingFeatures = "client";
    extraUpFlags = [
      "--accept-dns=false" # disable magic DNS
      "--accept-routes" # autmatically accept subnet routes advertised by other nodes
    ];
  };
  
}