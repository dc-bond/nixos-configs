{ pkgs, inputs, ... }: 

{

  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.hyprland}/bin/Hyprland";
        user = "chris";
      };
      #default_session = initial_session;
    };
  };  

}