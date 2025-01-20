{ 
  lib, 
  config, 
  pkgs, 
  ... 
}: 

{

  services.resolved = {
    enable = false; # ensure not enabled in favor of resolvconf below because running pihole
    llmnr = "false"; # disable link-local multicast name resolution
  };

  networking = {
    useDHCP = false; # disable default dhcpcd networking backend in favor of systemd-networkd enabled below
    hostName = "cypress";
    firewall = {
      enable = true;
    };
    resolvconf = {
      #useLocalResolver = true;
      dnsSingleRequest = true;
      extraConfig = "name_servers='127.0.0.1 1.1.1.1 9.9.9.9'";
    };
  };

  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false; # for wait-online error - need to find proper solution
  systemd.network = {
    enable = true;
    #wait-online.anyInterface = true; # systemd's wait-online target only requires that at least one managed interface be up instead of all managed interfaces
    networks = {
      "05-loopback" = {
        matchConfig.Name = "lo";
        linkConfig.RequiredForOnline = "no";
      };    
      "10-ethernet" = {
        matchConfig.Name = "enp1s0";
        networkConfig.DHCP = "ipv4";
        dhcpV4Config.RouteMetric = 300;
        dhcpV6Config.RouteMetric = 300;
        linkConfig.RequiredForOnline = "no";
      };    
    };
  };
}
