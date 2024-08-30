{ 
  pkgs, 
  ... 
}: 

{

  programs.plasma = {
    enable = true;
    overrideConfig = true;
    workspace = {
      clickItemTo = "open";
      lookAndFeel = "org.kde.breezedark.desktop";
    };
    configFile = {
      "kcminputrc"."Libinput/5426/154/Razer ProClickM"."PointerAcceleration" = "-0.400"; # set mouse speed
      "kcminputrc"."Keyboard"."NumLock" = 0; # set numlock on when logging in
      "kcminputrc"."Keyboard"."RepeatDelay" = 200; # set keyboard repeat delay
    };
    #cursor = {
    #  theme = "Bibata-Modern-Ice";
    #  size = 32;
    #};
    #iconTheme = "Papirus-Dark";
    #wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Patak/contents/images/1080x1920.png";
    };

}