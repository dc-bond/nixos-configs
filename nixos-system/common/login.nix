{ 
  pkgs,
  ... 
}: 

#let
#  greeter = "${pkgs.greetd.tuigreet}/bin/tuigreet";
#  session = "${pkgs.hyprland}/bin/Hyprland";
#  username = "chris";
#in

{

  #services.greetd = {
  #  enable = true;
  #  settings = {
  #    default_session = {
  #      command = "${greeter} --theme 'border=magenta;text=cyan;prompt=green;time=red;action=blue;button=yellow;container=black;input=red' --greeting 'access is restricted to authorized personnel' --asterisks --remember --remember-user-session --time -cmd ${session}";
  #      user = "greeter";
  #    };
  #  };
  #};


  services = {
    xserver.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      settings.General.DefaultSession = "hyprland.desktop";
    };
  };

}