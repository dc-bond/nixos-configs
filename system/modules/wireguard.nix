{ lib, config, pkgs, ... }: 

let
  wgIpv4 = "172.22.1.6/32";
  wgFwMark = 4242;
  wgTable = 4000;
in

{

  sops = {
    secrets = {
      wg-key = {
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
          PrivateKeyFile = "${config.sops.secrets.wg-key.path}";
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
              PersistentKeepalive = 25;
              RouteTable = "off";
            };
          }
        ];
      };

    };
    
    networks = {

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
            Family = "both";
            Table = "thinkpad-firewall";
            SuppressPrefixLength = 0;
            Priority = 10;
          };
        }
        {
          routingPolicyRuleConfig = {
            Family = "both";
            InvertRule = true;
            FirewallMark = wgFwMark;
            Table = wgTable;
            Priority = 11;
          };
        }
        ];
        routes = [
          {
            routeConfig = {
              Destination = "0.0.0.0/0";
              Table = wgTable;
              Scope = "link";
            };
          }
          {
            routeConfig = {
              Destination = "::/0";
              Table = wgTable;
              Scope = "link";
            };
          }
        ];
        linkConfig = {
          ActivationPolicy = "manual";
          RequiredForOnline = "no";
        };
      };    
    };
  
  };

}