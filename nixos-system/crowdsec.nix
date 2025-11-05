{ 
  pkgs, 
  ... 
}: 

{

  services.crowdsec = {
    enable = true;
  };

}