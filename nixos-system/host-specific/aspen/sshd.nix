{ 
  pkgs, 
  ... 
}: 

{

  services.openssh = {
    enable = true;
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