{ 
  lib, 
  config, 
  pkgs, 
  ... 
}: 

{

  services.resolved = {
    enable = true; # use systemd-resolved for DNS functionality
    llmnr = "false"; # disable link-local multicast name resolution
  };

  networking = {
    useDHCP = false; # disable default dhcpcd networking backend in favor of systemd-networkd enabled below
    hostName = "juniper";
    firewall = {
      enable = true; # enable default iptables
    };
  };

  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;
  systemd.network = {
    enable = true;
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