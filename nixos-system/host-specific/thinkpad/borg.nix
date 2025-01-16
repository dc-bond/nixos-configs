{ 
  pkgs,
  config,
  lib,
  configVars,
  ... 
}: 

{
  
  options.backups = {
    borgCypressRepo = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/borg-backups/cypress";
      description = "path to the cypress borg backup repository";
    };
    borgRestoreDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/borg-backups";
      description = "path to the directory for restoring borg backups";
    };
  };

  config = {

    services.borgbackup.repos = {
      aspen = {
        authorizedKeys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII11a3XF34ysN/xseM/UZmU7/Y4/JmMCTmBsoxlQ3Jqn borg@aspen"];
        path = "/var/lib/borg-backups/aspen";
      };
      cypress = {
        authorizedKeys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOpolyGOcVqcrl1Kp+brigrMsrD9R194SGG9+L5ubZe3 borg@cypress"];
        path = "/var/lib/borg-backups/cypress";
      };
    };

  };

}