{ 
  config, 
  configVars,
  pkgs, 
  lib,
  ... 
}:

let
  app = "uptime-kuma";
  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";
  recoveryPlan = {
    serviceName = "${app}";
    localRestoreRepoPath = "${config.backups.borgDir}/${config.networking.hostName}";
    cloudRestoreRepoPath = "${config.backups.borgCloudDir}/${config.networking.hostName}";
    restoreItems = [ "/var/lib/private/${app}" ];
    stopServices = [ "${app}" ];
    startServices = [ "${app}" ];
  };
  recoverUptimeKumaScript = pkgs.writeShellScriptBin "recoverUptimeKuma" ''
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
  
  sops.secrets.borgCryptPasswd = {};

  environment.systemPackages = with pkgs; [ recoverUptimeKumaScript ];

  backups.serviceHooks = {
    preHook = lib.mkAfter [
      "systemctl stop ${app}.service"
    ];
    postHook = lib.mkAfter [
      "systemctl start ${app}.service"
    ];
  };

  services = {

    ${app}.enable = true;

    borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;

    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [
          "trusted-allow"
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
            url = "http://127.0.0.1:3001";
          }
          ];
        };
      };
    };

  };

}