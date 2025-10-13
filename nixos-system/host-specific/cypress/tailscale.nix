{ 
  pkgs, 
  config,
  configVars,
  lib,
  ... 
}: 

{

  sops.secrets.cypressTailscaleAuthKey = {};

  networking.firewall.trustedInterfaces = ["tailscale0"];

  services = {
    tailscale = {
      enable = true;
      authKeyFile = "${config.sops.secrets.cypressTailscaleAuthKey.path}";
      useRoutingFeatures = "client";
      extraDaemonFlags = ["--no-logs-no-support"];
      extraUpFlags = [
        "-ssh" # enable tailscale-ssh
        "--accept-routes" # autmatically discover and accept subnet routes advertised by other nodes
      ];
    };
  };

}