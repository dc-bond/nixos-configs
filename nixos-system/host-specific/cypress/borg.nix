{ 
  pkgs,
  config,
  configVars,
  configLib,
  ... 
}: 

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
        repo = "borg@${configVars.thinkpadTailscaleIp}:."; # this automatically picks up the location of the remote borg repository assuming remote is running a nixos borg module
        encryption = {
          mode = "repokey-blake2"; # encrypt using password and save encryption key inside repository
          passCommand = "cat ${config.sops.secrets.borgCryptPasswd.path}";
        };
        environment = { 
          BORG_RSH = "ssh -p 28764 -o StrictHostKeyChecking=no -i /root/.ssh/borg-ed25519-cypress"; # requires manual creation and transfer of private/public keys (see script)
        };
        compression = "auto,zstd,8";
        paths = [
          "/var/lib/traefik"
          "/var/lib/private/lldap"
          "/var/lib/authelia-opticon"
          "/var/lib/hass"
          "/var/lib/mosquitto"
          "/var/lib/docker/volumes/zwavejs"
          "/var/backup/postgresql/hass.sql.gz"
          "/var/backup/postgresql/lldap.sql.gz"
        ];
        prune.keep = {
          daily = 7; # keep the last seven daily archives
          monthly = 3; # keep the last three monthly archives
        };
      };
    };
  };

}