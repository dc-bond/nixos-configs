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
  mongoShutdownWait = ''
    echo "Waiting for MongoDB to shutdown completely ..."

    TIMEOUT=60
    while [ $TIMEOUT -gt 0 ]; do
      # check if MongoDB port is still listening
      if ! ss -tlnp | grep -q "127.0.0.1:27117"; then
        # double-check: ensure the specific mongod process is gone
        if ! pgrep -f "mongod.*27117" > /dev/null; then
          echo "MongoDB process and port both stopped ..."
          break
        fi
      fi
      
      echo "MongoDB still running, waiting ... ($TIMEOUT seconds left)"
      sleep 2
      TIMEOUT=$((TIMEOUT - 2))
    done
    
    if [ $TIMEOUT -eq 0 ]; then
      echo "WARNING: MongoDB did not shut down within 60 seconds ..."
      # force kill the specific mongod process
      pkill -f "mongod.*27117" || true
      sleep 3
    fi
    
    # clean up lock files that can cause corruption
    echo "Cleaning up MongoDB lock files ..."
    rm -f /var/lib/unifi/data/db/mongod.lock
    rm -f /var/lib/unifi/data/db/WiredTiger.lock
    
    echo "MongoDB shutdown complete and lock files cleaned ..."
  '';
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
    postSvcStopHook = mongoShutdownWait;
  };
  
in

{

  sops.secrets.borgCryptPasswd = {};
  
  environment.systemPackages = with pkgs; [ recoverScript ];

  backups.serviceHooks = {
    preHook = lib.mkAfter (
      (map (svc: "systemctl stop ${svc}.service") recoveryPlan.stopServices) ++
      [ mongoShutdownWait ]
    );
    postHook = lib.mkAfter (
      map (svc: "systemctl start ${svc}.service") recoveryPlan.startServices
    );
  };

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