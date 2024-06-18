{ pkgs, ... }: 

{
  
# networking
  networking = {
    useDHCP = false;
    hostName = "thinkpad";
    nftables.enable = true; # use nftables for the firewall instead of default iptables
    firewall = {
      enable = true;
      allowedTCPPorts = [ 
        # 28764 # not needed as openssh server if active automatically opens its port(s)
      ];
    };
    # https://git.kernel.org/pub/scm/network/wireless/iwd.git/tree/src/iwd.network.rst
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
  systemd.network = {
    enable = true;
    wait-online.anyInterface = true; # systemd's wait-online target only requires that at least one managed interface be up instead of all managed interfaces
    networks = {
      #"10-enp0s31f6" = {
      #  matchConfig.Name = "enp0s31f6";
      #  networkConfig.DHCP = "ipv4";
      #  linkConfig.RequiredForOnline = "no";
      #};    
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
      #"40-wg0" = {
      #  matchConfig.Name = "wg0";
      #  address = ["172.22.1.6/32"];
      #  gateway = [
      #    ""
      #    ""
      #  ];
      #  DHCP = "no";
      #  dns = ["192.168.1.2"];
      #  #ntp = [""];
      #  networkConfig.IPv6AcceptRA = false;
      #  linkConfig.RequiredForOnline = "no";
      #};    
    #netdevs = {
    #  "40-wg0" = {
    #    netdevConfig = {
    #      Kind = "wireguard";
    #      Name = "wg0";
    #      MTUBytes = "1500";
    #    };
    #    wireguardConfig = {
    #      # Don't use a file from the Nix store as these are world readable. Must be readable by the systemd.network user
    #      PrivateKeyFile = "/run/keys/wireguard-privkey";
    #      PrivateKeyFile = outside-config.sops.secrets.wg-private-key.path;
    #      ListenPort = 9918;
    #    };
    #    wireguardPeers = [
    #      {
    #        wireguardPeerConfig = {
    #          PublicKey = "JH+yC7BcAp2G7l24/8KtwCI0pwLMdYw4e2r59TyrFnk=";
    #          AllowedIPs = ["0.0.0.0/0" "::/0"];
    #          Endpoint = "vpn.dcbond.com:51820";
    #          #PersistentKeepalive = "25";
    #        };
    #      }
    #    ];
    #  };
    #};
    };
  };
  
}