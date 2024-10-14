{ 
  lib, 
  config, 
  pkgs, 
  ... 
}: 

let
  wgIpv4 = "172.22.1.6/32";
  wgFwMark = 4242;
  wgTable = 4000;
in

{

  sops = {
    secrets = {
      wgKey = {
        owner = "${config.users.users.systemd-network.name}";
        group = "${config.users.users.systemd-network.group}";
        mode = "0440";
      };
    };
  };

  networking = {
    nftables = {
      tables = {
        wireguard-wg0 = {
          name = "wireguard-wg0";
          family = "inet";
          enable = true;
          content = 
            ''
              chain preraw {
                type filter hook prerouting priority raw; policy accept;
                iifname != "wg0" ip daddr ${wgIpv4} fib saddr type != local drop
              }
              chain premangle {
                type filter hook prerouting priority mangle; policy accept;
                meta l4proto udp meta mark set ct mark
              }
              chain postmangle {
                type filter hook postrouting priority mangle; policy accept;
                meta l4proto udp meta mark ${toString wgFwMark} ct mark set meta mark
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
  };

  systemd.network = {
    netdevs = {
      "40-wg0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
          MTUBytes = "1420";
        };
        wireguardConfig = {
          PrivateKeyFile = "${config.sops.secrets.wgKey.path}";
          ListenPort = 9918;
          FirewallMark = wgFwMark;
          RouteTable = "off";
        };
        
        wireguardPeers = [
          {
            wireguardPeerConfig = {
              PublicKey = "JH+yC7BcAp2G7l24/8KtwCI0pwLMdYw4e2r59TyrFnk="; # wireguard server pubkey
              AllowedIPs = [
                "0.0.0.0/0" 
                "::/0"
              ];
              Endpoint = "vpn.opticon.dev:51820"; # wireguard server address
              #Endpoint = "${config.sops.secrets.opticonUrl.path}:${config.sops.secrets.opticonVpnPort.path}"; # wireguard server address
              PersistentKeepalive = 25;
              RouteTable = "off";
            };
          }
        ];
        
        #wireguardPeers = [ # unstable?
        #  {
        #    PublicKey = "JH+yC7BcAp2G7l24/8KtwCI0pwLMdYw4e2r59TyrFnk="; # wireguard server pubkey
        #    AllowedIPs = [
        #      "0.0.0.0/0" 
        #      "::/0"
        #    ];
        #    Endpoint = "${config.sops.secrets.wgServer.path}:${config.sops.secrets.wgPort.path}"; # wireguard server address
        #    PersistentKeepalive = 25;
        #    RouteTable = "off";
        #  }
        #];
        
      };
    };
    networks = {
      "40-wg0" = {
        matchConfig.Name = "wg0";
        networkConfig = {
          Address = "${wgIpv4}";
          DNS = "192.168.1.2";
          #DNS = "${config.sops.secrets.opticonInternalIp.path}";
          DNSDefaultRoute = true; # make wireguard tunnel the default route for all DNS requests
          Domains = "~."; # default DNS route for all domains
        };
        linkConfig = {
          ActivationPolicy = "manual";
          RequiredForOnline = "no";
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
        
        #routingPolicyRules = [ # unstable?
        #  {
        #    Family = "both";
        #    Table = "thinkpad-firewall";
        #    SuppressPrefixLength = 0;
        #    Priority = 10;
        #  }
        #  {
        #    Family = "both";
        #    InvertRule = true;
        #    FirewallMark = wgFwMark;
        #    Table = wgTable;
        #    Priority = 11;
        #  }
        #];

        routes = [
          {
            routeConfig = {
              Destination = "0.0.0.0/0";
              Table = wgTable;
            };
          }
        ];

        #routes = [ # unstable?
        #  {
        #    Destination = "0.0.0.0/0";
        #    Table = wgTable;
        #    Scope = "link";
        #  }
        #  {
        #    Destination = "::/0";
        #    Table = wgTable;
        #    Scope = "link";
        #  }
        #];

      };    
    };
  };

}