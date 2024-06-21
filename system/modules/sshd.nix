{ lib, pkgs, config, ... }: 

{

  services.openssh = {
    enable = true;
    ports = [
      28764
      #config.sops.secrets.sshd-port.path # NEED TO FIX
    ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };

  sops = {
    secrets = {
      sshd-port = {};
    };
  };
  
}