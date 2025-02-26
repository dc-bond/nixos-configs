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
        #repo = "borg@${configVars.thinkpadLanIp}:."; # this automatically picks up the location of the remote borg repository assuming remote is running a nixos borg module
        repo = "${config.backups.borgDir}/${config.networking.hostName}";
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
          #BORG_RSH = "ssh -p 28764 -o StrictHostKeyChecking=no -i /root/.ssh/borg-ed25519-cypress"; # requires manual creation and transfer of private/public keys (see script)
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
          systemctl stop photoprism.service
          systemctl stop docker-zwavejs-root.target
          systemctl stop docker-pihole-root.target
          systemctl stop docker-actual-root.target
          systemctl stop docker-chromium-root.target
          systemctl stop docker-searxng-root.target
          systemctl stop docker-unifi-controller-root.target
          sleep 10 
          systemctl start postgresqlBackup-hass.service
          systemctl start postgresqlBackup-lldap.service
          systemctl start postgresqlBackup-nextcloud.service
          systemctl start postgresqlBackup-matrix-synapse.service
          systemctl start mysql-backup.service
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
          systemctl start traefik.service
          systemctl start photoprism.service
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
          echo "starting cloud backup"
          systemctl start cloudBackup.service
        '';
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

}