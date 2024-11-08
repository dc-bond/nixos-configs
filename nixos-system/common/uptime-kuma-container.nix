{ 
  config, 
  configVars,
  pkgs, 
  lib,
  ... 
}:

let
  app = "uptime-kuma";
in

{
  
  containers.${app} = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    #hostBridge = "br0";
    hostAddress = "${configVars.aspenBridgeSubnet}";
    localAddress = "${configVars.uptime-kumaIp}";
    config = {config, pkgs, lib, ...}: {
      services = {
        ${app}.enable = true;
        resolved = {
          enable = true; # use systemd-resolved for DNS functionality inside container
          llmnr = "false"; # disable link-local multicast name resolution inside container
        };
      };
      networking = {
        firewall = {
          enable = true;
          allowedTCPPorts = [3001];
        };
        #interfaces."eth0" = {
        #  ipv4.addresses = [
        #    {
        #    address = "${configVars.uptime-kumaIp}";
        #    prefixLength = 24;
        #    }
        #  ];
        #};
        useHostResolvConf = lib.mkForce false; # use systemd-resolved inside the container
      };
      system.stateVersion = "23.11";
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.${app} = {
      entrypoints = ["websecure"];
      rule = "Host(`${app}.${configVars.domain3}`)";
      service = "${app}";
      middlewares = [
        "auth-chain"
      ];
      tls = {
        certResolver = "cloudflareDns";
        options = "tls-13@file";
      };
    };
    services.${app} = {
      loadBalancer = {
        passHostHeader = true;
        servers = [
        {
          url = "http://${configVars.uptime-kumaIp}:3001";
        }
        ];
      };
    };
  };

}