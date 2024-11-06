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

  services.${app}.enable = true;

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
          url = "http://localhost:3001";
        }
        ];
      };
    };
  };

}

#  containers.${app} = {
#    autoStart = true;
#    ephemeral = true;
#    privateNetwork = true;
#    hostAddress = "${configVars.aspenIp}";
#    #hostBridge = "br0";
#    localAddress = "${appContainerIp}";
#    #forwardPorts = [ # I don't think port forwarding should be necessary but doesn't work regardless.
#    #{
#    #  containerPort = 3001;
#    #  hostPort = 3500;
#    #  protocol = "tcp";
#    #}
#    #];
#    config = {config, pkgs, lib, ...}: {
#      services = {
#        ${app}.enable = true;
#        resolved = {
#          enable = true; # use systemd-resolved for DNS functionality inside container
#          llmnr = "false"; # disable link-local multicast name resolution inside container
#        };
#      };
#      networking = {
#        firewall = {
#          enable = true;
#          allowedTCPPorts = [ 3001 ];
#        };
#        useHostResolvConf = lib.mkForce false; # use systemd-resolved inside the container
#      };
#      system.stateVersion = "23.11";
#    };
#  };