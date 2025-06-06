{ 
  lib, 
  config, 
  pkgs, 
  ... 
}: 

{

  services.resolved = {
    enable = lib.mkForce false; # ensure not enabled because running pihole on port 53
  };

  # manually set static nameservers - primary as 127.0.0.1 for internal pihole-unbound service, fallback as 1.1.1.1 if pihole-unbound stopped/broken
  environment.etc."resolv.conf".text = ''
    nameserver 127.0.0.1
    nameserver 1.1.1.1
  '';

  networking = {
    useDHCP = false; # disable default dhcpcd networking backend in favor of systemd-networkd enabled below
    hostName = "aspen";
    firewall = {
      enable = true;
    };
    resolvconf = {
      enable = lib.mkForce false;
    };
  };

  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false; # for wait-online error - need to find proper solution
  systemd.network = {
    enable = true;
    networks = {
      "05-loopback" = {
        matchConfig.Name = "lo";
        linkConfig.RequiredForOnline = "no";
      };    
      "10-ethernet" = {
        matchConfig.Name = "enp4s0";
        networkConfig.DHCP = "ipv4";
        dhcpV4Config.RouteMetric = 300;
        dhcpV6Config.RouteMetric = 400;
        linkConfig.RequiredForOnline = "no";
      };    
    };
  };
}
