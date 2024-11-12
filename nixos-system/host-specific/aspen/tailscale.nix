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

  #systemd.network = {
  #  networks = {
  #    "20-tailscale" = {
  #      matchConfig.Name = "tailscale0";
  #      #networkConfig.DHCP = "ipv4";
  #      #dhcpV4Config.RouteMetric = 300;
  #      #dhcpV6Config.RouteMetric = 300;
  #      linkConfig.RequiredForOnline = "no";
  #    };    
  #  };
  #};

  services.tailscale = {
    enable = true;
    authKeyFile = "${config.sops.secrets.tailscaleAuthKey.path}";
    useRoutingFeatures = "client";
    #openFirewall = true;
    #extraUpFlags = [
    #  "--accept-dns=false" # disable magic DNS?
    #];
  };
  
}