{ 
  pkgs, 
  config,
  configVars,
  lib,
  ... 
}: 

{

  sops.secrets.juniperTailscaleAuthKey = {};

  networking.firewall.trustedInterfaces = ["tailscale0"];

  services = {
    tailscale = {
      enable = true;
      authKeyFile = "${config.sops.secrets.juniperTailscaleAuthKey.path}";
      useRoutingFeatures = "server";
      extraDaemonFlags = ["--no-logs-no-support"];
      extraUpFlags = [
        "-ssh" # enable tailscale-ssh
        "--advertise-exit-node" # advertise as exit node
      ];
    };
  };

}