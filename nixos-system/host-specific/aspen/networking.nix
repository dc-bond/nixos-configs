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
    useDHCP = false; # disable defaut dhcpcd networking backend in favor of systemd-networkd enabled below
    hostName = "aspen";
    firewall = {
      enable = true;
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
        matchConfig.Name = "enp0s3";
        networkConfig.DHCP = "ipv4";
        dhcpV4Config.RouteMetric = 300;
        dhcpV6Config.RouteMetric = 300;
        linkConfig.RequiredForOnline = "no";
      };    
    };
  };
}