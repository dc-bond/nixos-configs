{ 
  pkgs, 
  ... 
}: 

{

  services.openssh = {
    enable = true; # automatically opens firewall port 22 unless alternate port specified below
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