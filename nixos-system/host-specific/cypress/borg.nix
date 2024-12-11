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
          BORG_RSH = "ssh -p 28764 -o StrictHostKeyChecking=no -i /root/.ssh/borg-ed25519"; # requires manual creation and transfer of private/public keys (see below)
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

# ssh-keygen -N '' -t ed25519 -f ./borg-ed25519
# scp borg-ed25519 chris@cypress-tailscale:/tmp && ssh chris@cypress-tailscale "sudo mv /tmp/borg-ed25519 /root/.ssh/ && sudo chmod 600 /root/.ssh/borg-ed25519 && sudo chown root:root /root/.ssh/borg-ed25519"
# copy pubkey to repo host borg config