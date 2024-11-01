{ 
  config, 
  configVars,
  pkgs, 
  lib,
  ... 
}:

let
  app = "uptime-kuma";
  appContainerIp = "172.21.1.3";
in

{

  containers.${app} = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    hostAddress = "${configVars.aspenIp}";
    localAddress = "${appContainerIp}";
    #forwardPorts = [ # I don't think port forwarding should be necessary but doesn't work regardless.
    #{
    #  containerPort = 3001;
    #  hostPort = 3500;
    #  protocol = "tcp";
    #}
    #];
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
        #"authelia" 
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
          #url = "http://localhost:3001"; # only works when uptime-kuma is not running in a container
          #url = "172.21.1.1:3001"; # 404 not found error in the traefik access log
          url = "http://${appContainerIp}:3001"; # what I think should work from reading the wiki page but 502 bad gateway error in the traefik access log
          #url = "http://${appContainerIp}:3001"; # something chatGPT reccomended but 502 bad gateway error in the traefik access log
        }
        ];
      };
    };
  };

}