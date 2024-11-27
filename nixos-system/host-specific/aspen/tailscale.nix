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
      useRoutingFeatures = "server";
      extraDaemonFlags = ["--no-logs-no-support"];
      extraUpFlags = [
        "--ssh" # enable devices on tailnet to ssh into this machine over tailscale on port 22
        #"--advertise-routes=" # autmatically discover and accept subnet routes advertised by other nodes
        "--advertise-exit-node" # advertise as exit node
      ];
    };
    #networkd-dispatcher = {
    #  enable = true;
    #  rules."50-tailscale" = {
    #    onState = ["routable"];
    #    script = ''
    #      ${lib.getExe ethtool} -K enp0s3 rx-udp-gro-forwarding on rx-gro-list off
    #    '';
    #  };
    #};
  };
  
}