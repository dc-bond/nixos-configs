{ 
  config, 
  lib,
  pkgs, 
  configVars,
  nixServiceRecoveryScript,
  ... 
}:

let

  app = "authelia-${configVars.domain1Short}";
  recoveryPlan = {
    restoreItems = [
      "/var/lib/${app}"
      "/var/lib/redis-${app}"
    ];
    stopServices = [ "${app}" "redis-${app}" ];
    startServices = [ "redis-${app}" "${app}" ];
  };
  recoverScript = nixServiceRecoveryScript {
    serviceName = app;
    recoveryPlan = recoveryPlan;
  };

in

{

  imports = [ inputs.simple-nixos-mailserver.nixosModule ];

  sops.secrets = {
    autheliaLdapUserPasswd1 = {
      owner = config.users.users."${app}".name;
      group = config.users.users."${app}".group;
      mode = "0440";
    };
  };

  environment.systemPackages = with pkgs; [ recoverScript ];
  
  backups.serviceHooks = {
    preHook = lib.mkAfter [
      "systemctl stop ${app}.service"
      "systemctl stop redis-${app}.service"
      "sleep 2"
    ];
    postHook = lib.mkAfter [
      "systemctl start redis-${app}.service"
      "systemctl start ${app}.service"
    ];
  };

  services = {


    redis.servers."${app}" = { # service name will be "redis-authelia-dcbond"
      enable = true;
      user = "${app}";   
      port = 0;
      unixSocket = "/run/redis-${app}/redis.sock";
      unixSocketPerm = 600;
    };

    #postgresql = {
    #  ensureDatabases = [ "${app}" ];
    #  ensureUsers = [
    #    {
    #      name = "${app}"; 
    #      ensureDBOwnership = true;
    #      ensureClauses.login = true;
    #    }
    #  ];
    #};

    #postgresqlBackup = {
    #  databases = [ "${app}" ];
    #};
      
    borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;

    # this creates traefik router, middleware, and service called "authelia-dcbond" that other apps can point to in their traefik configs
    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`identity.${configVars.domain1}`)";
        service = "${app}";
        middlewares = [
          "secure-headers"
        ];
        tls = {
          certResolver = "cloudflareDns";
          options = "tls-13@file";
        };
      };
      middlewares.${app} = {
        forwardAuth = {
          address = "http://127.0.0.1:9091/api/verify?rd=https://identity.${configVars.domain1}";
          trustForwardHeader = true;
          authResponseHeaders = [
            "Remote-User"
            "Remote-Groups"
            "Remote-Name"
            "Remote-Email"
          ];
        };
      };
      services.${app} = {
        loadBalancer = {
          passHostHeader = true;
          servers = [
          {
            url = "http://127.0.0.1:9091";
          }
          ];
        };
      };
    };

  };

}