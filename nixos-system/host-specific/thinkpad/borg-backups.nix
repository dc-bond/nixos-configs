{ 
  pkgs,
  config,
  lib,
  configVars,
  ... 
}: 

{
  
  options.backups = {
    borgDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/borgbackup";
      description = "path to the directory for borg backups";
    };
    borgCloudDir = lib.mkOption {
      type = lib.types.path;
      default = "${config.backups.borgDir}/cloud-restore";
      description = "path to the directory for borg backups restored from cloud storage (e.g. backblaze)";
    };
  };

  #config = {

  #  services.borgbackup.repos = {
  #    cypress = {
  #      authorizedKeys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOpolyGOcVqcrl1Kp+brigrMsrD9R194SGG9+L5ubZe3 borg@cypress"];
  #      path = "${config.backups.borgDir}/cypress";
  #    };
  #  };

  #};

}