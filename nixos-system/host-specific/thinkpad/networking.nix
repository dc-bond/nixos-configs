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
    hostName = "thinkpad";
    firewall.enable = true; # enable default iptables
    wireless.iwd = { 
      enable = true;
      settings = {
        IPv6 = {
        Enabled = false;
        };
        Settings = {
          AutoConnect = false;
          AlwaysRandomizeAddress = false;
        };
      };
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
        matchConfig.Name = "enp0s31f6";
        networkConfig.DHCP = "ipv4";
        dhcpV4Config.RouteMetric = 300;
        dhcpV6Config.RouteMetric = 400;
        linkConfig.RequiredForOnline = "no";
      };    
      "20-ethernet-dock" = {
        matchConfig.Name = "enp0s20f0u2u1u2";
        networkConfig.DHCP = "ipv4";
        dhcpV4Config.RouteMetric = 300;
        dhcpV6Config.RouteMetric = 400;
        linkConfig.RequiredForOnline = "no";
      };    
      "30-wifi" = {
        matchConfig.Name = "wlan0";
        networkConfig = {
          DHCP = "ipv4";
          IgnoreCarrierLoss = "3s"; # avoid re-configuring interface when wireless roaming between APs
        };
        dhcpV4Config.RouteMetric = 500;
        dhcpV6Config.RouteMetric = 600;
        linkConfig.RequiredForOnline = "no";
      };
    };
  };
}
