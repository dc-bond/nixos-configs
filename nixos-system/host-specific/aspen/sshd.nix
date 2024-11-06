{ 
  pkgs, 
  ... 
}: 

{

  services.openssh = {
    enable = true; # automatically opens ports in firewall
    ports = [
      28766
    ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };

}