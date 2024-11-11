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

  networking = {
    nat.internalInterfaces = ["ve-${app}"];
  };

  containers.${app} = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    #hostBridge = "br0";
    hostAddress6 = "${configVars.kumaHostVethIp}";
    localAddress6 = "${configVars.kumaContainerVethIp}";
    #forwardPorts = [
    #{
    #  containerPort = 3001;
    #  hostPort = 3001;
    #  protocol = "tcp";
    #}
    #];
    config = {config, pkgs, lib, ...}: {
      services = {
        ${app} = {
          enable = true;
        };
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
          #url = "http://${configVars.kumaHostVethIp}:3001";
          url = "http://${configVars.kumaContainerVethIp}:3001";
        }
        ];
      };
    };
  };

}