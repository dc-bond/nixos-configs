{ lib, pkgs, config, ... }: 

{

  services.openssh = {
    enable = true;
    ports = [
      28764
      #config.sops.secrets.sshd-port.path
    ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };
  
}