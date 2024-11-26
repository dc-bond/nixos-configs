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
        paths = [
          "/var/lib/nextcloud"
          "/var/backup/postgresql"
        ];
        #exclude = [ 
        #  "/nix" 
        #  "/path/to/local/repo" 
        #];
        repo = "borg@${configVars.thinkpadTailscaleIp}:."; # this automatically picks up the location of the remote borg repository assuming remote is running a nixos borg module
        doInit = true;
        encryption = {
          mode = "repokey-blake2";
          passCommand = "cat ${config.sops.secrets.borgCryptAspenPasswd.path}";
        };
        environment = { 
          BORG_RSH = "ssh -vvv -p 22 -o StrictHostKeyChecking=no -i /root/.ssh/borg-ed25519"; # requires manual setup of private/public keys
        };
        compression = "auto,zstd,8";
        prune.keep = {
          daily = 7; # keep the last seven daily archives
          monthly = 3; # keep the last three monthly archives
        };
        extraCreateArgs = [
          "--stats"
          #"--checkpoint-interval 600"
        ];
        startAt = "daily";
        dateFormat = "+%Y.%m.%d-T%H:%M:%S";
      };
    };
  };

}