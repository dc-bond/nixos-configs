{ lib, config, pkgs, ... }: 

let
  wgIpv4 = "172.22.1.6/22";
  wgFwMark = "0x8888";
  wgserverIp = "73.154.234.24";
  wgTable = 1000;
  #wgFwMark = 4242;
  #wgTable = 4000;
in

{

  services.resolved.enable = true; # use systemd-resolved for DNS functionality

  networking = {
    useDHCP = false; # disable defaut dhcpcd networking backend in favor of systemd-networkd enabled below
    hostName = "thinkpad";
    nftables = {
      enable = true; # use nftables for the firewall instead of default iptables
      #ruleset = 
      #''
      #  table inet wg-wg0 {
      #    chain preraw {
      #      type filter hook prerouting priority raw; policy accept;
      #      iifname != "wg0" ip daddr ${wgIpv4} fib saddr type != local drop
      #    }
      #    chain premangle {
      #      type filter hook prerouting priority mangle; policy accept;
      #      meta l4proto udp meta mark set ct mark
      #    }
      #    chain postmangle {
      #      type filter hook postrouting priority mangle; policy accept;
      #      meta l4proto udp meta mark ${toString wgFwMark} ct mark set meta mark
      #    }
      #  }
      #'';
    };
    #firewall = {
    #  enable = true;
    #  #allowedTCPPorts = [ 
    #  #  # 28764 # not needed as openssh server if active automatically opens its port(s)
    #  #];
    #  #allowedUDPPorts = [ 
    #  #  # 51820 # wireguard in server mode
    #  #];
    #};
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
    
    netdevs = {
      "99-wg0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
        };
        wireguardConfig = {
          PrivateKeyFile = "${config.sops.secrets.wg-key.path}";
          ListenPort = 9918;
          FirewallMark = wgFwMark;
        };
        wireguardPeers = [
          {
            wireguardPeerConfig = {
              PublicKey = "JH+yC7BcAp2G7l24/8KtwCI0pwLMdYw4e2r59TyrFnk="; # wireguard opticon server pubkey
              AllowedIPs = [
                "0.0.0.0/0" 
              ];
              #Endpoint = "vpn.opticon.dev:51820"; # wireguard opticon server address
              Endpoint = "${wgServerIp}:51820"; # wireguard opticon server address
              PersistentKeepalive = 25;
            };
          }
        ];
      };
    };

    #netdevs = {
    #  "40-wg0" = {
    #    netdevConfig = {
    #      Kind = "wireguard";
    #      Name = "wg0";
    #      MTUBytes = "1420";
    #    };
    #    wireguardConfig = {
    #      PrivateKeyFile = "${config.sops.secrets.wg-key.path}";
    #      ListenPort = 9918;
    #      FirewallMark = wgFwMark;
    #      RouteTable = "off";
    #    };
    #    wireguardPeers = [
    #      {
    #        wireguardPeerConfig = {
    #          PublicKey = "JH+yC7BcAp2G7l24/8KtwCI0pwLMdYw4e2r59TyrFnk="; # wireguard opticon server pubkey
    #          AllowedIPs = [
    #            "0.0.0.0/0" 
    #            "::/0"
    #          ];
    #          Endpoint = "vpn.opticon.dev:51820"; # wireguard opticon server address
    #          PersistentKeepalive = 25;
    #          RouteTable = "off";
    #        };
    #      }
    #    ];
    #  };
    #};
    
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

      "40-wg0" = {
        matchConfig.Name = "wg0";
        networkConfig = {
          Address = "${wgIpv4}";
          DNS = "192.168.1.2";
          DNSDefaultRoute = true; # make wireguard tunnel the default route for all DNS requests
          Domains = "~."; # default DNS route for all domains
        };
        routingPolicyRules = [
        {
          routingPolicyRuleConfig = {
            InvertRule = true;
            FirewallMark = wgFwMark;
            Table = wgTable;
            Priority = 10;
          };
        }
      ];
      routes = [
        {
          routeConfig = {
            Destination = "0.0.0.0/0";
            Table = wgTable;
          };
        }
      ];
        linkConfig = {
          ActivationPolicy = "manual";
          RequiredForOnline = "no";
        };
      };    
    };

      #"40-wg0" = {
      #  matchConfig.Name = "wg0";
      #  networkConfig = {
      #    Address = "${wgIpv4}";
      #    DNS = "192.168.1.2";
      #    DNSDefaultRoute = true; # make wireguard tunnel the default route for all DNS requests
      #    Domains = "~."; # default DNS route for all domains
      #  };
      #  routingPolicyRules = [
      #  {
      #    routingPolicyRuleConfig = {
      #      Family = "both";
      #      Table = "main";
      #      SuppressPrefixLength = 0;
      #      Priority = 10;
      #    };
      #  }
      #  {
      #    routingPolicyRuleConfig = {
      #      Family = "both";
      #      InvertRule = true;
      #      FirewallMark = wgFwMark;
      #      Table = wgTable;
      #      Priority = 11;
      #    };
      #  }
      #];
      #routes = [
      #  {
      #    routeConfig = {
      #      Destination = "0.0.0.0/0";
      #      Table = wgTable;
      #      Scope = "link";
      #    };
      #  }
      #  {
      #    routeConfig = {
      #      Destination = "::/0";
      #      Table = wgTable;
      #      Scope = "link";
      #    };
      #  }
      #];
      #  linkConfig = {
      #    ActivationPolicy = "manual";
      #    RequiredForOnline = "no";
      #  };
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