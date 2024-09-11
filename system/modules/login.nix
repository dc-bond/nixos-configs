{ 
pkgs,
... 
}: 

let
  greeter = "${pkgs.greetd.tuigreet}/bin/tuigreet";
  session = "${pkgs.hyprland}/bin/Hyprland";
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
        command = "${greeter} --theme 'border=magenta;text=cyan;prompt=green;time=red;action=blue;button=yellow;container=black;input=red' --greeting 'access is restricted to authorized personnel' --asterisks --remember --remember-user-session --time -cmd ${session}";
        user = "greeter";
      };
    };
  };

}