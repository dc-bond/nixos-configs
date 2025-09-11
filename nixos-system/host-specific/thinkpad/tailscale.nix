{ 
  pkgs, 
  config,
  configVars,
  lib,
  ... 
}: 

{

  sops.secrets.thinkpadTailscaleAuthKey = {};

  networking.firewall.trustedInterfaces = ["tailscale0"];

  services = {
    tailscale = {
      enable = true;
      authKeyFile = "${config.sops.secrets.thinkpadTailscaleAuthKey.path}";
      useRoutingFeatures = "client";
      extraDaemonFlags = ["--no-logs-no-support"];
      extraUpFlags = [
        "-ssh" # enable tailscale-ssh
        "--accept-routes" # autmatically discover and accept subnet routes advertised by other nodes
        "--exit-node=${configVars.juniperTailscaleIp}" # use exit node
      ];
    };
  };

}