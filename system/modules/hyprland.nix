{ 
pkgs,
inputs, 
config, 
... 
}: 

let
  tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet";
  session = "${pkgs.hyprland}/bin/Hyprland";
  username = "chris";
in

{

  programs.hyprland = {
    enable = true;
    package = pkgs.unstable.hyprland;
  };

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${session}";
        user = "${username}";
      };
      default_session = {
        command = "${tuigreet} --greeting 'Welcome to NixOS!' --asterisks --remember --remember-user-session --time -cmd ${session}";
        user = "greeter";
      };
    };
  };

}

  #imports = [
  #  inputs.hyprland.nixosModules.default # imported from flake inputs
  #];