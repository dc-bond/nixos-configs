{ lib, config, pkgs, ... }: 

{

  networking = {
    useDHCP = false;
    hostName = "thinkpad";
    nftables.enable = true; # use nftables for the firewall instead of default iptables
    wireguard.enable = true;
    firewall = {
      enable = true;
      #allowedTCPPorts = [ 
      #  # 28764 # not needed as openssh server if active automatically opens its port(s)
      #];
      #allowedUDPPorts = [ 
      #  # 51820 # wireguard in server mode
      #];
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
      #"40-wg0" = {
      #  matchConfig.Name = "wg0";
      #  #address = ["172.22.1.6/32"];
      #  #DHCP = "no";
      #  #dns = ["192.168.1.2"];
      #  networkConfig = {
      #    Address = "172.22.1.6/32";
      #    DNS = "192.168.1.2";
      #    IPv6AcceptRA = false;
      #    DNSDefaultRoute = true;
      #    Domains = "~.";
      #  };
      #  routingPolicyRules = {
      #    FirewallMark = "0x8888";
      #    InvertRule = true;
      #    Table = "1000";
      #    Priority = "10";
      #  };
      #  routes.routeConfig = {
      #    Destination = "0.0.0.0/0";
      #    Table = "1000";
      #  };
      #  linkConfig = {
      #    ActivationPolicy = "manual";
      #    RequiredForOnline = "no";
      #  };
      #};    
    };
    netdevs = {
      #"40-wg0" = {
      #  netdevConfig = {
      #    Kind = "wireguard";
      #    Name = "wg0";
      #    #MTUBytes = "1300";
      #  };
      #  wireguardConfig = {
      #    PrivateKeyFile = "${config.sops.secrets.wg-key.path}";
      #    ListenPort = 9918;
      #    FirewallMark = "0x8888";
      #  };
      #  wireguardPeers = [
      #    {
      #      wireguardPeerConfig = {
      #        PublicKey = "JH+yC7BcAp2G7l24/8KtwCI0pwLMdYw4e2r59TyrFnk="; # wireguard opticon server pubkey
      #        AllowedIPs = [
      #          "0.0.0.0/0" 
      #          "::/0"
      #        ];
      #        Endpoint = "vpn.opticon.dev:51820"; # wireguard opticon server address
      #        PersistentKeepalive = 25;
      #      };
      #    }
      #  ];
      #};
    };
  };

  sops = {
    secrets = {
      wg-key = {
        owner = "${config.users.users.systemd-network.name}";
        group = "${config.users.users.systemd-network.group}";
        mode = "0440";
      };
    };
  };
  
}