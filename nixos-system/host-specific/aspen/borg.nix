{ 
  pkgs,
  config,
  configVars,
  ... 
}: 

{

  #sops = {
  #  secrets = {
  #    chrisSshKey = {
  #      owner = "${config.users.users.root.name}";
  #      group = "${config.users.users.root.group}";
  #      mode = "0600";
  #      path = "/home/chris/.ssh/chris-ed25519.key";
  #    };
  #  };
  #};

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
        repo = "chris@${configVars.thinkpadLanIp}:/home/chris/borg-backups/aspen";
        doInit = true;
        encryption = {
          mode = "none";
          #passCommand = "cat ${config.sops.secrets.???.path}";
        };
        environment = { 
          BORG_RSH = "ssh -p 28764 -o StrictHostKeyChecking=no -i /root/.ssh/borg-ed25519"; # requires manual setup of private/public keys
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
        startAt = "hourly";
        dateFormat = "+%Y.%m.%d-T%H:%M:%S";
      };
    };
  };

}