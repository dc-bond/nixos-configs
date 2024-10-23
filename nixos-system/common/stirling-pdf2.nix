{ pkgs, 
  ... 
}:

{

  services = {
    stirling-pdf = {
      enable = true;
      environment = {
        SERVER_PORT = 16237;
      };
    };
  };

}
