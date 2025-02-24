{ 
  pkgs, 
  ... 
}: 

{

  services.openssh = {
    enable = true;
    ports = [
      28766 # automatically opens firewall port
    ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };

}