{ 
pkgs,
... 
}: 

let
  #tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet";
  greeter = "${pkgs.greetd.wlgreet}/bin/wlgreet";
  #session = "${pkgs.hyprland}/bin/Hyprland";
  username = "chris";
in

{

  #security.pam.services.login.enableGnomeKeyring = true;

  services.greetd = {
    enable = true;
    settings = {
      #initial_session = {
      #  command = "${session}";
      #  user = "${username}";
      #};
      default_session = {
        #command = "${greeter} --greeting 'Welcome to NixOS!' --asterisks --remember --remember-user-session --time -cmd ${session}";
        command = "${greeter}";
        user = "username";
      };
    };
  };

}