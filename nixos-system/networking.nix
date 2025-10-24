{ 
  lib, 
  config, 
  pkgs, 
  ... 
}: 

{

  services.resolved = {
    enable = lib.elem config.networking.hostName ["juniper" "thinkpad" "cypress"]; # use systemd-resolved for DNS functionality, defaults to "false" (e.g. for aspen)
    llmnr = "false"; # disable link-local multicast name resolution
  };

  environment.etc."resolv.conf" = lib.mkIf (config.networking.hostName == "aspen") { # networking.resolvconf.enable automatically sets itself to "false" (e.g. for aspen) if environment.etc."resolv.conf" defined
    text = ''
      nameserver 127.0.0.1
      nameserver 1.1.1.1
    '';
  };

  networking = {
    useDHCP = false; # disable default dhcpcd networking backend in favor of systemd-networkd enabled below
    firewall.enable = true;
    wireless.iwd = lib.mkIf (config.networking.hostName == "thinkpad") {
      enable = true;
      settings = {
        IPv6.Enabled = false;
        Settings = {
          AutoConnect = false;
          AlwaysRandomizeAddress = false;
        };
      };
    };
  };

  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;
  
  systemd.network = {
    enable = true;
    networks = {
      "05-loopback" = {
        matchConfig.Name = "lo";
        linkConfig.RequiredForOnline = "no";
      };
      "10-ethernet" = {
        matchConfig.Name = 
          if config.networking.hostName == "thinkpad" then "enp0s31f6"
          else if config.networking.hostName == "aspen" then "enp4s0"
          else "enp1s0"; # juniper and cypress fallback
        networkConfig.DHCP = "ipv4";
        dhcpV4Config.RouteMetric = 300;
        dhcpV6Config.RouteMetric = 400;
        linkConfig.RequiredForOnline = "no";
      };
    } // lib.optionalAttrs (config.networking.hostName == "thinkpad") {
      "20-ethernet-dock" = {
        matchConfig.Name = "enp0s20f0u2u1u2";
        networkConfig.DHCP = "ipv4";
        dhcpV4Config.RouteMetric = 300;
        dhcpV6Config.RouteMetric = 400;
        linkConfig.RequiredForOnline = "no";
      };
      "30-wifi" = {
        matchConfig.Name = "wlan0";
        networkConfig = {
          DHCP = "ipv4";
          IgnoreCarrierLoss = "3s"; # avoid re-configuring interface when wireless roaming between APs
        };
        dhcpV4Config.RouteMetric = 500;
        dhcpV6Config.RouteMetric = 600;
        linkConfig.RequiredForOnline = "no";
      };
    };
  };

}