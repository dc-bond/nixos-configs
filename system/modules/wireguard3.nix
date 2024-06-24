{ lib, config, pkgs, ... }: 

{

  sops = {
    secrets = {
      wg-key = {};
      wg-address = {};
    };
    templates."wg0.conf" = {
      content = 
      ''
        [Interface]
        Address = ${config.sops.placeholder.wg-address}
        ListenPort = 51820
        PrivateKey = ${config.sops.placeholder.wg-key}
        DNS = 192.168.1.2

        [Peer]
        PublicKey = JH+yC7BcAp2G7l24/8KtwCI0pwLMdYw4e2r59TyrFnk=
        AllowedIPs = 0.0.0.0/0, ::/0
        Endpoint = vpn.opticon.dev:51820
        PersistentKeepalive = 25
      '';
      path = "/etc/wireguard/wg0.conf";
    };
  };

  networking = {
    wireguard.enable = true;
    wg-quick = {
      interfaces = {
        wg0 = {
          #configFile = "${config.sops.secrets.wg0-conf.path}";
          configFile = /etc/wireguard/wg0.conf;
        };
      };
    };
  };
}
        #owner = "${config.users.users.systemd-network.name}";
        #group = "${config.users.users.systemd-network.group}";
        #mode = "0440";