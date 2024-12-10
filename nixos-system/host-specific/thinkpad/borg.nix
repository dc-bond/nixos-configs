{ 
  pkgs,
  config,
  configVars,
  ... 
}: 

{

  services.borgbackup.repos = {
    aspen = {
      authorizedKeys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII11a3XF34ysN/xseM/UZmU7/Y4/JmMCTmBsoxlQ3Jqn borg@aspen"];
      path = "/var/lib/borg-backups/aspen";
    };
    cypress = {
      authorizedKeys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII1J2Q3b8+L3s90kNEJQr8WQ98wlqoLSh4IiNBzBtLQM borg@cypress"];
      path = "/var/lib/borg-backups/cypress";
    };
  };

}