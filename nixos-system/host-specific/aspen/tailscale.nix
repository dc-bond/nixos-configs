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
      #useRoutingFeatures = "server";
      useRoutingFeatures = "client";
      #extraUpFlags = [
      #  #"--advertise-routes=" # advertise subnet routes for other nodes
      #  "--advertise-exit-node" # advertise as exit node
      #];
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