{ 
  pkgs, 
  ... 
}: 

{

  environment.systemPackages = with pkgs; [
    libsecret # secrets library for gnome keyring
  ];

  services.gnome.gnome-keyring.enable = true;
  #programs.seahorse.enable = true;

}