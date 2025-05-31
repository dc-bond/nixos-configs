{ 
  pkgs,
  config,
  lib,
  configVars,
  configLib,
  ... 
}: 

let

  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";

  listLocalArchivesScript = pkgs.writeShellScriptBin "listLocalArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    sudo -E ${pkgs.borgbackup}/bin/borg list ${config.backups.borgDir}/${config.networking.hostName}
  '';

  infoLocalArchivesScript = pkgs.writeShellScriptBin "infoLocalArchives" ''
    #!/bin/bash
    export BORG_PASSPHRASE=$(sudo cat ${borgCryptPasswdFile})
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    sudo -E ${pkgs.borgbackup}/bin/borg info ${config.backups.borgDir}/${config.networking.hostName}
  '';

in

{

  options.backups = {
    borgDir = lib.mkOption {
      type = lib.types.path;
      default = "${config.drives.storageDrive1}/borgbackup";
      description = "path to the directory for borg backups";
    };
    borgCloudDir = lib.mkOption {
      type = lib.types.path;
      default = "${config.backups.borgDir}/cloud-restore";
      description = "path to the directory for borg backups restored from cloud storage (e.g. backblaze)";
    };
  };
  
  config = {

    sops.secrets.borgCryptPasswd = {};
    
    environment.systemPackages = with pkgs; [ 
      listLocalArchivesScript
      infoLocalArchivesScript
    ];

    services.borgbackup.jobs = {
      "${config.networking.hostName}" = {
        archiveBaseName = "${config.networking.hostName}";
        repo = "${config.backups.borgDir}/${config.networking.hostName}";
        dateFormat = "+%Y.%m.%d-T%H:%M:%S";
        doInit = true; # run borg init if backup directory does not already contain the repository
        failOnWarnings = false;
        extraCreateArgs = [
          "--progress"
          "--stats"
        ];
        startAt = "*-*-* 02:45:00"; # everyday at 2:45am
        encryption = {
          mode = "repokey-blake2"; # encrypt using password and save encryption key inside repository
          passCommand = "cat ${config.sops.secrets.borgCryptPasswd.path}";
        };
        environment = { 
          BORG_RELOCATED_REPO_ACCESS_IS_OK = "yes"; # supress warning about repo location being moved since last backup (e.g. changing directory location or IP address)
        };
        compression = "auto,zstd,8";
        readWritePaths = [ "/var/lib/nextcloud/" ]; # needed to allow borgbackup readwrite access to nextcloud directory containing occ command execution (for turning on/off maintenance mode)
        preHook = ''
          set -x
          echo "spinning down services and starting sql database dumps"
         	${lib.getExe config.services.nextcloud.occ} maintenance:mode --on || exit 1
          systemctl stop traefik.service
          systemctl stop photoprism.service
          systemctl stop lldap.service
          systemctl stop authelia-dcbond.service
          systemctl stop redis-authelia-dcbond.service
          systemctl stop matrix-synapse.service
          systemctl stop redis-matrix-synapse.service
          systemctl stop uptime-kuma.service
          systemctl stop docker-searxng-root.target
          systemctl stop docker-media-server-root.target
          systemctl stop docker-recipesage-root.target
          systemctl stop docker-chromium-root.target
          sleep 10 
          systemctl start mysql-backup.service
          systemctl start postgresqlBackup-lldap.service
          systemctl start postgresqlBackup-matrix-synapse.service
          systemctl start postgresqlBackup-nextcloud.service
          sleep 10 
        '';
        postHook = ''
          set -x
          echo "spinning up services"
          ${lib.getExe config.services.nextcloud.occ} maintenance:mode --off || exit 1
          systemctl start traefik.service
          systemctl start photoprism.service
          systemctl start lldap.service
          systemctl start redis-authelia-dcbond.service
          systemctl start authelia-dcbond.service
          systemctl start redis-matrix-synapse.service
          systemctl start matrix-synapse.service
          systemctl start uptime-kuma.service
          systemctl start docker-searxng-root.target
          systemctl start docker-media-server-root.target
          systemctl start docker-recipesage-root.target
          systemctl start docker-chromium-root.target
          echo "starting cloud backup"
          systemctl start cloudBackup.service
        '';
        paths = [
          "/home/${configVars.userName}/email"
          "/var/lib/traefik"
          "/var/lib/private/photoprism"
          "/var/lib/private/lldap"
          "/var/lib/private/uptime-kuma"
          "/var/lib/authelia-dcbond"
          "/var/lib/redis-authelia-dcbond"
          "/var/lib/matrix-synapse"
          "/var/lib/redis-matrix-synapse"
          "/var/lib/nextcloud"
          "/var/lib/redis-nextcloud"
          "/var/lib/docker/volumes/jellyfin"
          "/var/lib/docker/volumes/jellyseerr"
          "/var/lib/docker/volumes/sabnzbd"
          "/var/lib/docker/volumes/prowlarr"
          "/var/lib/docker/volumes/radarr"
          "/var/lib/docker/volumes/sonarr"
          "/var/lib/docker/volumes/searxng"
          "/var/lib/docker/volumes/recipesage-api"
          "/var/lib/docker/volumes/recipesage-postgres"
          "/var/lib/docker/volumes/recipesage-typesense"
          "/var/lib/docker/volumes/chromium"
          "/var/backup/mysql/photoprism.gz"
          "/var/backup/postgresql/lldap.sql.gz"
          "/var/backup/postgresql/matrix-synapse.sql.gz"
          "/var/backup/postgresql/nextcloud.sql.gz"
          "${config.drives.storageDrive1}/media/family-media"
        ];
        prune.keep = {
          daily = 7; # keep the last seven daily archives
          monthly = 3; # keep the last three monthly archives
        };
      };
    };
    
  };

}