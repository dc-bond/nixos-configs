{ 
  pkgs, 
  ... 
}: 

{

  services.openssh = {
    enable = true;
    ports = [
      28764
    ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };

}