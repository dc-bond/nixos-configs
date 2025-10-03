{ 
  pkgs, 
  config,
  configVars,
  lib,
  nixServiceRecoveryScript,
  ... 
}: 

let

  app = "unifi";
  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";
  recoveryPlan = {
    serviceName = "${app}";
    localRestoreRepoPath = "${config.backups.borgDir}/${config.networking.hostName}";
    cloudRestoreRepoPath = "${config.backups.borgCloudDir}/${config.networking.hostName}";
    restoreItems = [
      "/var/lib/${app}"
    ];
    stopServices = [ "${app}" ];
    startServices = [ "${app}" ];
  };
  recoverScript = nixServiceRecoveryScript {
    serviceName = app;
    recoveryPlan = recoveryPlan;
    postSvcStopHook = ''
      echo "Waiting for MongoDB to shutdown completely ..."
      sleep 20
    '';
  };
  
in

{

  sops.secrets.borgCryptPasswd = {};
  
  environment.systemPackages = with pkgs; [ recoverScript ];

  backups.serviceHooks = {
    preHook = lib.mkAfter (
      (map (svc: "systemctl stop ${svc}.service") recoveryPlan.stopServices) ++
      [ "sleep 20" ]
    );
    postHook = lib.mkAfter (
      map (svc: "systemctl start ${svc}.service") recoveryPlan.startServices
    );
  };

  #backups.serviceHooks = {
  #  preHook = lib.mkAfter [
  #    "systemctl stop ${app}.service"
  #    "sleep 30" # ensure mongodb has enough time to gracefully shutdown before starting /var/lib/unifi directory backup
  #  ];
  #  postHook = lib.mkAfter [
  #    "systemctl start ${app}.service"
  #  ];
  #};

  networking.firewall = {
    allowedUDPPorts = [ 
      #1900 # required for 'make controller discoverable on L2 network' option
      #3478 # STUN port
      #5514 # remote syslog port
      10001 # AP discovery port
    ];
    allowedTCPPorts = [ 
      6789 # mobile throughput test
      8080 # device communication port
      #8443 # web admin port, not necessary to open if traefik sitting in front
      #8843 # guest portal https redirect port
      #8880 # guest portal http redirect port
    ];
  };

  services = {

    "${app}".enable = true;

    borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;

    traefik = {

      staticConfigOptions.serversTransport.insecureSkipVerify = true;
      dynamicConfigOptions.http = {
        routers.${app} = {
          entrypoints = ["websecure"];
          rule = "Host(`${app}.${configVars.domain2}`)";
          service = "${app}";
          middlewares = [
            "${app}-headers"
            "secure-headers"
            "trusted-allow"
          ];
          tls = {
            certResolver = "cloudflareDns";
            options = "tls-13@file";
          };
        };
        middlewares."${app}-headers".headers.customRequestHeaders.Authorization = "";
        services.${app} = {
          loadBalancer = {
            passHostHeader = true;
            servers = [
            {
              url = "https://127.0.0.1:8443"; # unifi web ui runs with TLS termination on port 8443
            }
            ];
          };
        };
      };

    };

  };

}