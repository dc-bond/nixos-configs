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
  mongoShutdownWait = ''
    echo "Waiting for Unifi's MongoDB subprocess to shutdown completely ..."

    TIMEOUT=60
    while [ $TIMEOUT -gt 0 ]; do
      PORT_OPEN=false
      PROCESS_RUNNING=false
      
      # check port with full path (use netstat as fallback)
      if ${pkgs.iproute2}/bin/ss -tlnp 2>/dev/null | grep -q "127.0.0.1:27117" 2>/dev/null; then
        PORT_OPEN=true
      elif ${pkgs.nettools}/bin/netstat -tlnp 2>/dev/null | grep -q "127.0.0.1:27117" 2>/dev/null; then
        PORT_OPEN=true
      fi
      
      # check process with full path
      if ${pkgs.procps}/bin/pgrep -f "mongod.*27117" >/dev/null 2>&1; then
        PROCESS_RUNNING=true
      fi
      
      # if both port and process are gone, we're done
      if [ "$PORT_OPEN" = "false" ] && [ "$PROCESS_RUNNING" = "false" ]; then
        echo "Unifi MongoDB subprocess and port both stopped ..."
        break
      fi
      
      echo "Unifi's MongoDB subprocess still running, waiting ... ($TIMEOUT seconds left)"
      sleep 2
      TIMEOUT=$((TIMEOUT - 2))
    done
    
    if [ $TIMEOUT -eq 0 ]; then
      echo "WARNING: Unifi's MongoDB subprocess did not shut down within 60 seconds ..."
      ${pkgs.procps}/bin/pkill -f "mongod.*27117" 2>/dev/null || true
      sleep 3
    fi

    echo "Unifi MongoDB subprocess shutdown complete ..."
  '';
  recoveryPlan = {
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