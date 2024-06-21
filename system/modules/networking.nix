{ lib, config, pkgs, ... }: 

{

  networking = {
    useDHCP = false;
    hostName = "thinkpad";
    nftables.enable = true; # use nftables for the firewall instead of default iptables
    firewall = {
      enable = true;
      #allowedTCPPorts = [ 
      #  # 28764 # not needed as openssh server if active automatically opens its port(s)
      #];
      #allowedUDPPorts = [ 
      #  # 51820 # wireguard
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
      "10-enp0s31f6" = {
        matchConfig.Name = "enp0s31f6";
        networkConfig.DHCP = "ipv4";
        linkConfig.RequiredForOnline = "no";
      };    
      "20-enp0s20f0u2u1u2" = {
        matchConfig.Name = "enp0s20f0u2u1u2";
        networkConfig.DHCP = "ipv4";
        linkConfig.RequiredForOnline = "no";
      };    
      "30-wlan0" = {
        matchConfig.Name = "wlan0";
        networkConfig.DHCP = "ipv4";
        linkConfig.RequiredForOnline = "no";
      };    
      "40-wg-thinkpad" = {
        matchConfig.Name = "wg-thinkpad";
        address = ["172.22.1.6/32"];
        gateway = [
          ""
          ""
        ];
        DHCP = "no";
        dns = ["192.168.1.2"];
        #ntp = [""];
        networkConfig.IPv6AcceptRA = false;
        linkConfig.RequiredForOnline = "no";
      };    
    };
    netdevs = {
      "40-wg-thinkpad" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg-thinkpad";
          MTUBytes = "1500";
        };
        wireguardConfig = {
          PrivateKeyFile = "${config.sops.secrets.wg-key.path}";
          ListenPort = 9918;
        };
        wireguardPeers = [
          {
            wireguardPeerConfig = {
              PublicKey = "JH+yC7BcAp2G7l24/8KtwCI0pwLMdYw4e2r59TyrFnk="; # wireguard server pubkey
              AllowedIPs = ["0.0.0.0/0" "::/0"];
              Endpoint = "vpn.dcbond.com:51820"; # wireguard server address
              #PersistentKeepalive = "25";
            };
          }
        ];
      };
    };
  };

  sops = {
    secrets = {
      wg-key = {
        owner = "${config.users.users.systemd-network.name}";
        group = "${config.users.users.systemd-network.group}";
        mode = "0440";
        #restartUnits = [ "systemd-networkd.service" ];
      };
    };
  };
  
}