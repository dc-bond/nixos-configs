{ 
  pkgs,
  config,
  lib,
  configVars,
  configLib,
  ... 
}: 

          #${lib.getExe config.services.nextcloud.occ} maintenance:mode --on
          #${lib.getExe config.services.nextcloud.occ} maintenance:mode --off
{

  sops.secrets = {
    borgCryptPasswd = {};
  };

  services.borgbackup = {
    jobs = {
      cypress = {
        archiveBaseName = "cypress";
        dateFormat = "+%Y.%m.%d-T%H:%M:%S";
        doInit = true; # run borg init if backup directory does not already contain the repository
        failOnWarnings = false;
        extraCreateArgs = [
          "--progress"
          "--stats"
        ];
        startAt = "*-*-* 02:30:00"; # everyday at 2:30am
        preHook = ''
          set -x
          echo "spinning down services and starting sql database dumps"
          systemctl start nextcloudMaintenanceOn.service
          sleep 10 
          systemctl stop authelia-dcbond.service
          systemctl stop redis-authelia-dcbond.service
          systemctl stop lldap.service
          systemctl stop uptime-kuma.service
          systemctl stop home-assistant.service
          systemctl stop mosquitto.service
          systemctl stop traefik.service
          systemctl start postgresqlBackup-hass.service
          systemctl start postgresqlBackup-lldap.service
          systemctl start postgresqlBackup-nextcloud.service
          systemctl stop docker-zwavejs-root.target
          systemctl stop docker-pihole-root.target
          systemctl stop docker-actual-root.target
          systemctl stop docker-chromium-root.target
          systemctl stop docker-searxng-root.target
          sleep 30 
        '';
        postHook = ''
          set -x
          echo "spinning services back up"
          systemctl start nextcloudMaintenanceOff.service
          systemctl start docker-zwavejs-root.target
          systemctl start docker-pihole-root.target
          systemctl start docker-actual-root.target
          systemctl start traefik.service
          systemctl start redis-authelia-dcbond.service
          systemctl start lldap.service
          systemctl start authelia-dcbond.service
          systemctl start uptime-kuma.service
          systemctl start home-assistant.service
          systemctl start mosquitto.service
          systemctl start docker-chromium-root.target
          systemctl start docker-searxng-root.target
        '';
        repo = "borg@${configVars.thinkpadLanIp}:."; # this automatically picks up the location of the remote borg repository assuming remote is running a nixos borg module
        encryption = {
          mode = "repokey-blake2"; # encrypt using password and save encryption key inside repository
          passCommand = "cat ${config.sops.secrets.borgCryptPasswd.path}";
        };
        environment = { 
          BORG_RSH = "ssh -p 28764 -o StrictHostKeyChecking=no -i /root/.ssh/borg-ed25519-cypress"; # requires manual creation and transfer of private/public keys (see script)
          BORG_RELOCATED_REPO_ACCESS_IS_OK = "yes"; # supress warning about repo location being moved since last backup (e.g. changing directory location or IP address)
        };
        compression = "auto,zstd,8";
        paths = [
          "/var/lib/traefik"
          "/var/lib/private/lldap"
          "/var/lib/private/uptime-kuma"
          "/var/lib/authelia-dcbond"
          "/var/lib/redis-authelia-dcbond"
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
          "/var/backup/postgresql/hass.sql.gz"
          "/var/backup/postgresql/lldap.sql.gz"
          "/var/backup/postgresql/nextcloud.sql.gz"
        ];
        prune.keep = {
          daily = 7; # keep the last seven daily archives
          monthly = 3; # keep the last three monthly archives
        };
      };
    };
  };

}