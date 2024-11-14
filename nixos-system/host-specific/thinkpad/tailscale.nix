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
        "--accept-routes" # autmatically discover and accept subnet routes advertised by other nodes
        "--exit-node=100.92.225.78"
      ];
    };
  };

  #systemd.services.tailscaled.serviceConfig.Environment = lib.mkAfter ["TS_NO_LOGS_NO_SUPPORT=true"];

}