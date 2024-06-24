{ lib, config, pkgs, ... }: 

{

  sops = {
    secrets = {
      wg-key = {
        owner = "${config.users.users.systemd-network.name}";
        group = "${config.users.users.systemd-network.group}";
        mode = "0440";
      };
      wg-address = {
        owner = "${config.users.users.systemd-network.name}";
        group = "${config.users.users.systemd-network.group}";
        mode = "0440";
      };
      wg-server = {
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
          MTUBytes = "1300";
        };
        wireguardConfig = {
          PrivateKeyFile = "${config.sops.secrets.wg-key.path}";
          ListenPort = 9918;
        };
        wireguardPeers = [
          {
            wireguardPeerConfig = {
              PublicKey = "JH+yC7BcAp2G7l24/8KtwCI0pwLMdYw4e2r59TyrFnk="; # wireguard server pubkey
              AllowedIPs = ["0.0.0.0/0"];
              Endpoint = "${config.sops.secrets.wg-server.path}:51820"; # wireguard server address
              PersistentKeepalive = 25;
            };
          }
        ];
      };
    };
    networks = {
      "40-wg0" = {
        matchConfig.Name = "wg0";
        networkConfig = {
          Address = "${config.sops.secrets.wg-address.path}";
          DHCP = "no";
          DNS = "192.168.1.2";
          #Gateway = ;
          IPv6AcceptRA = false;
          
          #DNSDefaultRoute = true; # make wireguard tunnel the default route for all DNS requests
          #Domains = "~."; # default DNS route for all domains
        };
      };
    };
  };

}