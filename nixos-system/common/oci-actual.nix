{ 
  config,
  lib,
  pkgs, 
  configVars,
  ... 
}: 

let
  app = "actual";
  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";
  recoveryPlan = {
    serviceName = "${app}";
    localRestoreRepoPath = "${config.backups.borgDir}/${config.networking.hostName}";
    cloudRestoreRepoPath = "${config.backups.borgCloudDir}/${config.networking.hostName}";
    restoreItems = [
      "/var/lib/docker/volumes/${app}"
    ];
    stopServices = [ "docker-${app}-root.target" ];
    startServices = [ "docker-${app}-root.target" ];
  };
  recoverActualScript = pkgs.writeShellScriptBin "recoverActual" ''
    #!/bin/bash
   
    # track errors
    set -euo pipefail

    # set borg passphrase environment variable
    export BORG_PASSPHRASE=$(cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

    # repo selection
    read -p "Use cloud repo? (y/N): " use_cloud
    if [[ "$use_cloud" =~ ^[Yy]$ ]]; then
      REPO="${recoveryPlan.cloudRestoreRepoPath}"
      echo "Using cloud repo"
    else
      REPO="${recoveryPlan.localRestoreRepoPath}"
      echo "Using local repo"
    fi

    # archive selection
    echo "Available archives at $REPO:"
    echo ""
    archives=$(${pkgs.borgbackup}/bin/borg list --short "$REPO")
    echo "$archives" | nl -w2 -s') '
    echo ""
    read -p "Enter number: " num
    ARCHIVE=$(echo "$archives" | sed -n "''${num}p")
    if [ -z "$ARCHIVE" ]; then
      echo "Invalid selection"
      exit 1
    fi
    echo "Selected: $ARCHIVE"

    # stop services
    for svc in ${lib.concatStringsSep " " recoveryPlan.stopServices}; do
      echo "Stopping $svc ..."
      systemctl stop "$svc" || true
    done

    # extract data from archive and overwrite existing data
    cd /
    echo "Extracting data from $REPO::$ARCHIVE ..."
    ${pkgs.borgbackup}/bin/borg extract --verbose --list "$REPO"::"$ARCHIVE" ${lib.concatStringsSep " " recoveryPlan.restoreItems}
    
    # start services
    for svc in ${lib.concatStringsSep " " recoveryPlan.startServices}; do
      echo "Starting $svc ..."
      systemctl start "$svc" || true
    done

    echo "Recovery complete!"
  '';
in

{

  #environment.systemPackages = with pkgs; [ recoverActualScript ];
  
  backups.serviceHooks = {
    preHook = lib.mkAfter [ "systemctl stop docker-${app}-root.target" ];
    postHook = lib.mkAfter [ "systemctl start docker-${app}-root.target" ];
  };

  services.borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;
  
  sops.secrets.boryygCryptPasswd = {};
  
  virtualisation.oci-containers.containers."${app}" = {
    image = "docker.io/actualbudget/${app}-server:24.11.0";
    autoStart = true;
    log-driver = "journald";
    volumes = [ "${app}:/data" ];
    extraOptions = [
      "--network=${app}"
      "--ip=${configVars.actualIp}"
      "--tty=true"
      "--stop-signal=SIGINT"
    ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.${app}.entrypoints" = "websecure";
      "traefik.http.routers.${app}.rule" = "Host(`chris-allowance.${configVars.domain2}`)";
      "traefik.http.routers.${app}.tls" = "true";
      "traefik.http.routers.${app}.tls.options" = "tls-13@file";
      "traefik.http.routers.${app}.middlewares" = "trusted-allow@file,secure-headers@file";
      "traefik.http.services.${app}.loadbalancer.server.port" = "5006";
    };
  };

  systemd = {
    services = { 
      "docker-${app}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-volume-${app}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      "docker-network-${app}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${pkgs.docker}/bin/docker network rm -f ${app}";
        };
        script = ''
          docker network inspect ${app} || docker network create --subnet ${configVars.actualSubnet} --driver bridge --scope local --attachable ${app}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };
      "docker-volume-${app}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app} || docker volume create ${app}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };
    };
    targets."docker-${app}-root" = {
      unitConfig = {
        Description = "root target for docker-${app}";
      };
      wantedBy = ["multi-user.target"];
    };
  }; 

}