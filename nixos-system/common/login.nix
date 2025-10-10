{ 
  pkgs,
  ... 
}: 

{

  services = {
    displayManager.sddm = {
      enable = true;
      package = pkgs.kdePackages.sddm;
      wayland.enable = true;
      autoNumlock.enable = true;
      #settings = {
      #  Autologin = {
      #    Session = "hyprland.desktop";
      #    User = "chris";
      #  };
      #};
    };
  };

  environment.systemPackages = with pkgs; [
    kdePackages.sddm-kcm # configuration module for sddm
  ];

}