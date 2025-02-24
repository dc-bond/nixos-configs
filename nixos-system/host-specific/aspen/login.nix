{ 
  pkgs,
  ... 
}: 

let
  greeter = "${pkgs.greetd.tuigreet}/bin/tuigreet";
  #session = "${pkgs.hyprland}/bin/Hyprland";
in

{

  services.greetd = {
    enable = true;
    settings = {
      #initial_session = { # this bit automatically logs in, but breaks automatic unlocking of gnome-keyring
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