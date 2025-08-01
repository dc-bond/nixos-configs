{ 
  pkgs, 
  config,
  configVars,
  lib,
  ... 
}: 

{

  sops.secrets.tailscaleAuthKey = {};

  networking = {
    firewall.trustedInterfaces = ["tailscale0"];
    nat = { # enable subnet routing for tailscale without needing to serve as exit-node
      enable = true;
      internalInterfaces = [ "tailscale0" ];
      externalInterface = "enp4s0";
    };
  };

  services = {
    tailscale = {
      enable = true;
      authKeyFile = "${config.sops.secrets.tailscaleAuthKey.path}";
      useRoutingFeatures = "server";
      extraDaemonFlags = ["--no-logs-no-support"];
      extraUpFlags = [
        "-ssh" # enable tailscale-ssh
        "--advertise-exit-node" # advertise as exit node
        "--advertise-routes=192.168.1.0/24,192.168.4.0/27" # advertise home and iot vlan subnets
      ];
    };
  };

}