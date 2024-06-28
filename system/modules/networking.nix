{ lib, config, pkgs, ... }: 

{

  services.resolved = {
    enable = true; # use systemd-resolved for DNS functionality
    llmnr = "false"; # disable link-local multicast name resolution
  };

  networking = {
    useDHCP = false; # disable defaut dhcpcd networking backend in favor of systemd-networkd enabled below
    hostName = "thinkpad";
    firewall = {
      enable = false; # disable default iptables
    };
    nftables = {
      enable = true; # use nftables instead of default iptables
      tables = {
        thinkpad-firewall = {
          name = "thinkpad-firewall";
          family = "inet";
          enable = true;
          content = 
            ''
            	chain input {
            		type filter hook input priority 0; policy drop;
            		ct state invalid counter drop comment "early drop of invalid packets"
            		ct state {established, related} counter accept comment "accept all connections related to connections made by us"
            		iif lo accept comment "accept loopback"
            		iif != lo ip daddr 127.0.0.1/8 counter drop comment "drop connections to loopback not coming from loopback"
            		iif != lo ip6 daddr ::1/128 counter drop comment "drop connections to loopback not coming from loopback"
            		ip protocol icmp counter accept comment "accept all ICMP types"
            		meta l4proto ipv6-icmp counter accept comment "accept all ICMP types"
            		tcp dport 28764 counter accept comment "accept SSH"
            		counter comment "count dropped packets"
            	}
            	chain forward {
            		type filter hook forward priority 0; policy drop;
            		counter comment "count dropped packets"
            	}
            	chain output {
            		type filter hook output priority 0; policy accept;
            		counter comment "count accepted packets"
            	}
            '';
        };
      };
    };
    wireless.iwd = { 
      enable = true;
      settings = {
        IPv6 = {
        Enabled = false;
        };
        Settings = {
          AutoConnect = true;
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
        dhcpV6Config.RouteMetric = 300;
        linkConfig.RequiredForOnline = "no";
      };    
      "20-ethernet-dock" = {
        matchConfig.Name = "enp0s20f0u2u1u2";
        networkConfig.DHCP = "ipv4";
        dhcpV4Config.RouteMetric = 300;
        dhcpV6Config.RouteMetric = 300;
        linkConfig.RequiredForOnline = "no";
      };    
      "30-wifi" = {
        matchConfig.Name = "wlan0";
        networkConfig = {
          DHCP = "ipv4";
          IgnoreCarrierLoss = "3s"; # avoid re-configuring interface when wireless roaming between APs
        };
        dhcpV4Config.RouteMetric = 600;
        dhcpV6Config.RouteMetric = 600;
        linkConfig.RequiredForOnline = "no";
      };
    };
  };
}