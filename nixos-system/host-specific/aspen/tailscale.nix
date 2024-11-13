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

  #environment.systemPackages = with pkgs; [
  #  ethtool
  #  networkd-dispatcher 
  #];

  services = {
    tailscale = {
      enable = true;
      authKeyFile = "${config.sops.secrets.tailscaleAuthKey.path}";
      useRoutingFeatures = "server";
      extraUpFlags = [
        #"--accept-dns=false" # disable magic DNS
        #"--advertise-routes=" # advertise subnet routes for other nodes
        "--advertise-exit-node" # advertise as exit node
        #"--accept-routes" # autmatically accept subnet routes advertised by other nodes
      ];
      #extraSetFlags = [
      #  "--exit-node=opticon"
      #  "--exit-node-allow-lan-access=true"
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