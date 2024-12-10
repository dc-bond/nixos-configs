{ 
  pkgs,
  config,
  configVars,
  ... 
}: 

{

  sops.secrets = {
    borgCryptPasswd = {};
    borgSshKey = {};
  };
  #sops.templates = {
  #  "borg-ed25519".content = ''
  #    ${config.sops.placeholder.borgSshKey}
  #  '';
  #};

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
          #BORG_RSH = "ssh -p 28764 -o StrictHostKeyChecking=no -i /root/.ssh/borg-ed25519"; # requires manual setup of private/public keys
          BORG_RSH = "ssh -p 28764 -o StrictHostKeyChecking=no -i /run/secrets/borgSshKey"; # requires manual setup of private/public keys
        };
        compression = "auto,zstd,8";
        paths = [
          "/var/lib/hass"
        ];
        prune.keep = {
          daily = 7; # keep the last seven daily archives
          monthly = 3; # keep the last three monthly archives
        };
      };
    };
  };

}