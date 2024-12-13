{ 
  pkgs,
  config,
  configVars,
  ... 
}: 

{

  sops.secrets.borgCryptAspenPasswd = {};

  services.borgbackup = {
    jobs = {
      aspen = {
        archiveBaseName = "aspen";
        dateFormat = "+%Y.%m.%d-T%H:%M:%S";
        doInit = true; # run borg init if backup directory does not already contain the repository
        failOnWarnings = false;
        extraCreateArgs = [
          "--progress"
          "--stats"
        ];
        startAt = "*-*-* 02:30:00"; # everyday at 2:30am
        repo = "borg@${configVars.thinkpadTailscaleIp}:."; # this automatically picks up the location of the remote borg repository assuming remote is running a nixos borg module
        encryption = {
          mode = "repokey-blake2"; # encrypt using password and save encryption key inside repository
          passCommand = "cat ${config.sops.secrets.borgCryptAspenPasswd.path}";
        };
        environment = { 
          BORG_RSH = "ssh -p 28764 -o StrictHostKeyChecking=no -i /root/.ssh/borg-ed25519"; # requires manual setup of private/public keys
        };
        compression = "auto,zstd,8";
        paths = [
          "/var/lib/hass"
          #"/var/lib/traefik"
          #"/var/lib/nextcloud"
          #"/var/lib/uptime-kuma"
          #"/var/lib/redis-nextcloud"
          #"/var/lib/redis-authelia-professorbond"
          #"/var/lib/nextcloud"
          #"/var/lib/docker/volumes/jellyseerr"
          #"/var/lib/docker/volumes/lldap"
          #"/var/lib/docker/volumes/postgres-lldap"
          #"/var/backup/postgresql"
        ];
        #exclude = [ 
        #  "/nix" 
        #  "/path/to/local/repo" 
        #];
        prune.keep = {
          daily = 7; # keep the last seven daily archives
          monthly = 3; # keep the last three monthly archives
        };
      };
    };
  };

}