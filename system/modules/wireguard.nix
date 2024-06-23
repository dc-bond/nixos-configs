{ lib, config, pkgs, ... }: 

let
  wgIpv4 = "172.22.1.6/22";
  wgServerIp = "73.154.234.24";
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
    firewall = {
      allowedUDPPorts = [ 
        51820 # wireguard
      ];
    };
    wireguard = {
      enable = true;
      interfaces = {
        wg0 = {
          ips = [wgIpv4];
          listenPort = 51820; # to match firewall allowedUDPPorts (without this wg uses random port numbers)
          privateKeyFile = "${config.sops.secrets.wg-key.path}";
          peers = [
            {
              publicKey = "JH+yC7BcAp2G7l24/8KtwCI0pwLMdYw4e2r59TyrFnk="; # wireguard opticon server pubkey
              allowedIPs = [ "0.0.0.0/0" ];
              endpoint = "${wgServerIp}:51820"; # ToDo: route to endpoint not automatically configured https://wiki.archlinux.org/index.php/WireGuard#Loop_routing https://discourse.nixos.org/t/solved-minimal-firewall-setup-for-wireguard-client/7577
              persistentKeepalive = 25;
            }
          ];
        };
      };
    };
  };
}