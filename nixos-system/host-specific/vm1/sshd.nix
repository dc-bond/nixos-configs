{ 
  pkgs, 
  ... 
}: 

{

  services.openssh = {
    enable = true;
    ports = [
      28765
    ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };

}