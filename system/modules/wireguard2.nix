{ lib, config, pkgs, ... }: 

let
  wgFwMark = 4242;
  wgTable = 1000;
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

  systemd.network = {
    
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
              PublicKey = "JH+yC7BcAp2G7l24/8KtwCI0pwLMdYw4e2r59TyrFnk="; # wireguard server pubkey
              AllowedIPs = [
                "0.0.0.0/0" 
              ];
              Endpoint = "vpn.opticon.dev:51820"; # wireguard server address
              PersistentKeepalive = 25;
            };
          }
        ];
      };
      
    };

    networks = {

      "99-wg0" = {
        matchConfig.Name = "wg0";
        networkConfig = {
          Address = "172.22.1.6/22";
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
          ActivationPolicy = "manual"; # manually turn on/off wireguard tunnel with networkctl instead of automatically at boot
          RequiredForOnline = "no";
        };
      };    
    };
  
  };

}