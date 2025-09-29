{ 
  pkgs,
  lib,
  config,
  configVars, 
  ... 
}:

let
  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";
  
  # function that generates a recovery script for any dockerized container stack service
  makeDockerRecoveryScript = { serviceName, recoveryPlan }: 
    pkgs.writeShellScriptBin "recover${lib.strings.toUpper (builtins.substring 0 1 serviceName)}${builtins.substring 1 (-1) serviceName}" ''
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

      # allow for graceful container shutdown
      echo "Ensure container stack fully down..."
      sleep 15 
      
      # extract volume names from restore items
      VOLUMES=""
      for item in ${lib.concatStringsSep " " recoveryPlan.restoreItems}; do
        VOLUME_NAME=$(basename "$item")
        VOLUMES="$VOLUMES $VOLUME_NAME"
      done
      
      # remove existing volumes
      echo "Removing existing volumes..."
      for volume in $VOLUMES; do
        echo "Removing volume: $volume"
        ${pkgs.docker}/bin/docker volume rm "$volume" || true
      done
      
      # recreate volumes
      echo "Recreating volumes..."
      for volume in $VOLUMES; do
        echo "Creating volume: $volume"
        ${pkgs.docker}/bin/docker volume create "$volume"
      done

      # extract data from archive
      cd /
      echo "Extracting data from $REPO::$ARCHIVE ..."
      ${pkgs.borgbackup}/bin/borg extract --verbose --list "$REPO"::"$ARCHIVE" ${lib.concatStringsSep " " recoveryPlan.restoreItems}

      # start services
      for svc in ${lib.concatStringsSep " " recoveryPlan.startServices}; do
        echo "Starting $svc ..."
        systemctl start "$svc" || true
      done

      echo "Recovery complete for ${serviceName}!"
    '';
in

{

  virtualisation = {
    oci-containers.backend = "docker";
    docker = {
      enable = true;
      autoPrune.enable = true;
      storageDriver = "btrfs"; # support for btrfs
    };
  };

  users.users.${configVars.userName}.extraGroups = [ "docker" ];

  _module.args.makeDockerRecoveryScript = makeDockerRecoveryScript;

}
