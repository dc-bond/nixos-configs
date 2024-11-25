{ 
  pkgs,
  config,
  configVars,
  ... 
}: 

{

  #sops = {
  #  secrets = {
  #    ??? = {
  #      #owner = "${config.users.users.${app}.name}";
  #      #group = "${config.users.users.${app}.group}";
  #      #mode = "0440";
  #    };
  #  };
  #};

  services.borgbackup = {

    #repos = {
    #  borg-aspen = {
    #    authorizedKeys = [""];
    #    path = "/home/xixor/borg-aspen";
    #  };    
    #};

    jobs = {

      web-apps = {
        paths = [
          "/var/lib/nextcloud"
          "/var/backup/postgresql"
        ];
        #exclude = [ 
        #  "/nix" 
        #  "/path/to/local/repo" 
        #];
        repo = "xixor@${configVars.domain1}:/home/xixor/borgtestrepo";
        doInit = true;
        encryption = {
          mode = "none";
          #passphrase = "secret";
          #passCommand = "cat /root/borgbackup/passphrase";
          #passCommand = "cat ${config.sops.secrets.???.path}";
        };
        environment = { 
          BORG_RSH = "ssh -i /home/chris/.ssh/chris-ed25519.key"; 
        };
        compression = "auto,zstd";
        startAt = "hourly";
      };

    };

  };

}