{ 
  pkgs, 
  ... 
}: 

{

  services.openssh = {
    enable = true;
    ports = [
      28764 # automatically opens firewall port
    ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };

}