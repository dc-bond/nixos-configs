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
    privateNetwork = true;
    hostAddress = "192.168.1.186";
    localAddress = "172.21.1.1";
    #hostAddress6 = "fc00::1";
    #localAddress6 = "fc00::2";
    config = {config, pkgs, lib, ...}: {
      services = {
        uptime-kuma.enable = true;
        resolved = {
          enable = true; # use systemd-resolved for DNS functionality inside container
          llmnr = "false"; # disable link-local multicast name resolution inside container
        };
      };
      networking = {
        firewall = {
          enable = true;
          allowedTCPPorts = [ 3001 ];
        };
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
        "authelia" 
        "secure-headers"
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
          url = "http://localhost:3001";
          #url = "172.21.1.1:3001";
        }
        ];
      };
    };
  };

}