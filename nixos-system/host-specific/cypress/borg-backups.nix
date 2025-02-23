{ 
  pkgs,
  config,
  lib,
  configVars,
  configLib,
  ... 
}: 

let
  rcloneConf = "/run/secrets/rendered/rclone.conf";
  cypressBackupScript = pkgs.writeShellScriptBin "cypressBackup" ''
    #!/bin/bash
    echo "rclone cloud backup to backblaze started at $(date)"
    ${pkgs.rclone}/bin/rclone --config "${rcloneConf}" --verbose sync ${config.backups.borgDir}/cypress backblaze-b2:cypress-backup
    echo "rclone cloud backup to backblaze finished at $(date)"
    '';
  cypressRestoreScript = pkgs.writeShellScriptBin "cypressRestore" ''
    #!/bin/bash
    echo "rclone cloud restore from backblaze started at $(date)"
    if [ -d "${config.backups.borgCloudDir}/cypress" ]; then
      echo "stale restoration detected at ${config.backups.borgCloudDir}/cypress... deleting"
      rm -rf ${config.backups.borgCloudDir}/cypress
    fi
    echo "creating restoration directory at ${config.backups.borgCloudDir}/cypress"
    mkdir ${config.backups.borgCloudDir}/cypress
    ${pkgs.rclone}/bin/rclone --config "${rcloneConf}" --verbose sync backblaze-b2:cypress-backup ${config.backups.borgCloudDir}/cypress
    echo "change ownership of restoration directory at ${config.backups.borgCloudDir}/cypress to borg"
    chown -R borg:borg ${config.backups.borgCloudDir}/cypress
    echo "rclone cloud restore from backblaze finished at $(date)"
    '';
in

{
  
  options.backups = {
    borgDir = lib.mkOption {
      type = lib.types.path;
      default = "/media/WD-WX21DC86RU3P/borgbackup";
      description = "path to the directory for borg backups";
    };
    borgCloudDir = lib.mkOption {
      type = lib.types.path;
      default = "${config.backups.borgDir}/cloud-restore";
      description = "path to the directory for borg backups restored from cloud storage (e.g. backblaze)";
    };
  };
  
  environment.systemPackages = with pkgs; [ 
    cypressBackupScript
    cypressRestoreScript
    rclone
  ];

  #config = {

  #  services.borgbackup.repos = {
  #    cypress = {
  #      authorizedKeys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOpolyGOcVqcrl1Kp+brigrMsrD9R194SGG9+L5ubZe3 borg@cypress"];
  #      path = "${config.backups.borgDir}/cypress";
  #    };
  #  };

  #};
  
  sops = {
    secrets = {
      borgCryptPasswd = {};
      backblazeCypressAccount = {};
      backblazeCypressKey = {};
    };
    templates = {
      "rclone.conf".content = ''
        [backblaze-b2]
        type = b2
        account = ${config.sops.placeholder.backblazeCypressAccount}
        key = ${config.sops.placeholder.backblazeCypressKey}
        hard_delete = true
      '';
    };
  };

  services.borgbackup = {
    jobs = {
      cypress = {
        archiveBaseName = "cypress";
        repo = "${config.backups.borgDir}/cypress";
        dateFormat = "+%Y.%m.%d-T%H:%M:%S";
        doInit = true; # run borg init if backup directory does not already contain the repository
        failOnWarnings = false;
        extraCreateArgs = [
          "--progress"
          "--stats"
        ];
        startAt = "*-*-* 02:30:00"; # everyday at 2:30am
        encryption = {
          mode = "repokey-blake2"; # encrypt using password and save encryption key inside repository
          passCommand = "cat ${config.sops.secrets.borgCryptPasswd.path}";
        };
        environment = { 
          BORG_RELOCATED_REPO_ACCESS_IS_OK = "yes"; # supress warning about repo location being moved since last backup (e.g. changing directory location or IP address)
        };
        compression = "auto,zstd,8";
        preHook = ''
          set -x
          echo "spinning down services and starting sql database dumps"
          systemctl start nextcloudMaintenanceOn.service
          systemctl stop authelia-dcbond.service
          systemctl stop redis-authelia-dcbond.service
          systemctl stop matrix-synapse.service
          systemctl stop redis-matrix-synapse.service
          systemctl stop lldap.service
          systemctl stop uptime-kuma.service
          systemctl stop home-assistant.service
          systemctl stop mosquitto.service
          systemctl stop traefik.service
          systemctl stop docker-zwavejs-root.target
          systemctl stop docker-pihole-root.target
          systemctl stop docker-actual-root.target
          systemctl stop docker-chromium-root.target
          systemctl stop docker-searxng-root.target
          systemctl stop docker-unifi-controller-root.target
          systemctl stop docker-media-server-root.target
          sleep 10 
          systemctl start postgresqlBackup-hass.service
          systemctl start postgresqlBackup-lldap.service
          systemctl start postgresqlBackup-nextcloud.service
          systemctl start postgresqlBackup-matrix-synapse.service
          sleep 10
        '';
        postHook = ''
          set -x
          echo "spinning up services"
          systemctl start nextcloudMaintenanceOff.service
          systemctl start docker-unifi-controller-root.target
          systemctl start docker-zwavejs-root.target
          systemctl start docker-pihole-root.target
          systemctl start docker-actual-root.target
          systemctl start docker-media-server-root.target
          systemctl start traefik.service
          systemctl start redis-authelia-dcbond.service
          systemctl start lldap.service
          systemctl start authelia-dcbond.service
          systemctl start redis-matrix-synapse.service
          systemctl start matrix-synapse.service
          systemctl start uptime-kuma.service
          systemctl start home-assistant.service
          systemctl start mosquitto.service
          systemctl start docker-chromium-root.target
          systemctl start docker-searxng-root.target
        '';
          #echo "starting cloud backup"
          #systemctl start cypressBackup.service
        paths = [
          "/var/lib/traefik"
          "/var/lib/private/lldap"
          "/var/lib/private/uptime-kuma"
          "/var/lib/authelia-dcbond"
          "/var/lib/redis-authelia-dcbond"
          "/var/lib/matrix-synapse"
          "/var/lib/redis-matrix-synapse"
          "/var/lib/nextcloud"
          "/var/lib/redis-nextcloud"
          "/var/lib/hass"
          "/var/lib/mosquitto"
          "/var/lib/tailscale"
          "/var/lib/docker/volumes/zwavejs"
          "/var/lib/docker/volumes/pihole"
          "/var/lib/docker/volumes/unbound"
          "/var/lib/docker/volumes/actual"
          "/var/lib/docker/volumes/searxng"
          "/var/lib/docker/volumes/chromium"
          "/var/lib/docker/volumes/unifi-controller"
          "/var/lib/docker/volumes/unifi-controller-mongodb-db"
          "/var/lib/docker/volumes/unifi-controller-mongodb-configdb"
          "/var/lib/docker/volumes/jellyfin"
          "/var/lib/docker/volumes/jellyseerr"
          "/var/lib/docker/volumes/sabnzbd"
          "/var/lib/docker/volumes/prowlarr"
          "/var/lib/docker/volumes/radarr"
          "/var/lib/docker/volumes/sonarr"
          "/var/backup/postgresql/hass.sql.gz"
          "/var/backup/postgresql/lldap.sql.gz"
          "/var/backup/postgresql/nextcloud.sql.gz"
          "/var/backup/postgresql/matrix-synapse.sql.gz"
        ];
        prune.keep = {
          daily = 7; # keep the last seven daily archives
          monthly = 3; # keep the last three monthly archives
        };
      };
    };
  };

  systemd.services = {
    "cypressBackup" = {
      description = "rclone backup to backblaze cloud storage";
      serviceConfig = {
        ExecStart = "${cypressBackupScript}/bin/cypressBackup";
        Restart = "on-failure";
        EnvironmentFile = "${rcloneConf}";
      };
      preStart = ''
        if [ ! -f "${rcloneConf}" ]; then
          echo "rclone configuration file not found at ${rcloneConf}"
          exit 1
        fi
      '';
    };
    "cypressRestore" = {
      description = "rclone restore from backblaze cloud storage";
      serviceConfig = {
        ExecStart = "${cypressRestoreScript}/bin/cypressRestore";
        Restart = "on-failure";
        EnvironmentFile = "${rcloneConf}";
      };
      preStart = ''
        if [ ! -f "${rcloneConf}" ]; then
          echo "rclone configuration file not found at ${rcloneConf}"
          exit 1
        fi
      '';
    };
  };
  #  timers = {
  #    "cypressBackup" = {
  #      description = "systemd timer for cypressBackup service";
  #      wantedBy = [ "timers.target" ];
  #      timerConfig = {
  #        OnCalendar = "04:00:00"; # everyday at 4am
  #        Persistent = true; # ensure missed executions are run after the system is online again
  #      };
  #    };
  #  };
  #}; 

}