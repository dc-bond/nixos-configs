{ config, pkgs, ... }: 

{

## gnupg 
#  programs.gnupg = {
#    agent = {
#      enable = true;
#      enableSSHSupport = true;
#      settings = {
#        disable-scdaemon = true; # disable in favor of other package (pcsclite)
#      };
#    };
#  };

## disable ssh-agent systemwide
#  programs.ssh.startAgent = false;

}