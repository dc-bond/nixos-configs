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
    #firewall.extraCommands = ''
    #  iptables -w -t nat -A nixos-nat-post -s ${config.containers.uptime-kuma.localAddress} -j MASQUERADE
    #'';
    nat = {
      enable = true;
      externalInterface = "enp0s3";
      internalInterfaces = ["ve-uptime-kuma"];
      enableIPv6 = false;
    };
  };

  containers.${app} = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    hostAddress = "${configVars.uptime-kumaVethIp}";
    localAddress = "${configVars.uptime-kumaContainerIp}";
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
          url = "http://127.0.0.1:3001";
        }
        ];
      };
    };
  };

}