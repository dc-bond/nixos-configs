{ 
  pkgs, 
  config,
  configVars,
  lib,
  ... 
}: 

{

  sops.secrets.tailscaleAuthKey = {};

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
        "-ssh"
        "--accept-routes" # autmatically discover and accept subnet routes advertised by other nodes
        "--exit-node=${configVars.opticonTailscaleIp}"
        #"--exit-node-allow-lan-access" # allow client to access its own LAN while connected to an exit-node?
      ];
    };
  };

  #systemd.services.tailscaled.restartIfChanged = true;
  #systemd.services.tailscaled.serviceConfig.Environment = lib.mkAfter ["TS_NO_LOGS_NO_SUPPORT=true"];

}