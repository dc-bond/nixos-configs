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
    hostAddress = "192.168.1.186";
    localAddress = "172.21.1.1";
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
          #url = "http://localhost:3001"; # works when uptime-kuma is not running in a container, doesn't work when running in container
          url = "172.21.1.1:3001"; # 404 not found error in the traefik access log
          #url = "http://172.21.1.1:3001"; # 500 internal server error in the traefik access log
          #url = "http://${config.containers.${app}.hostAddress}:3001"; # some cryptic shit chat GPT reccomended but get a 500 error in the traefik access log
        }
        ];
      };
    };
  };

}