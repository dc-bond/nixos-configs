{ 
  pkgs,
  config,
  configVars,
  ... 
}: 

{

  services.borgbackup.repos = {
    aspen = {
    authorizedKeys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII11a3XF34ysN/xseM/UZmU7/Y4/JmMCTmBsoxlQ3Jqn borg@aspen"] ;
    path = "/home/chris/borg-backups/aspen" ;
    };
  };

}