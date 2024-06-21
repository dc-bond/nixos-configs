{ config, ... }: 

{

let
  sshd-port = config.sops.secrets.sshd-port.path;
in


  services.openssh = {
    enable = true;
    ports = [
      #28764
      $(cat ${sshd-port})
    ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };
  
}