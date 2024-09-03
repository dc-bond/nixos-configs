{ 
  pkgs, 
  ... 
}: 

{

  programs.plasma = {
    enable = true;
    overrideConfig = true;
    input = {
      keyboard = {
        repeatDelay = 200;
        repeatRate = 25.0;
        numlockOnStartup = "on";
      };
      #mice = [
      #  {
      #    acceleration = -0.5;
      #    accelerationProfile = "default";
      #    enable = true;
      #    leftHanded = false;
      #    middleButtonEmulation = false;
      #    name = "Razer ProClickM";
      #    naturalScroll = false;
      #    productId = "009a";
      #    scrollSpeed = 1;
      #    vendorId = "1532";
      #  }
      #];
    };
    kwin = {
      nightLight = {
        enable = true;
        mode = "times";
        temperature = {
          day = 6500;
          night = 4500;
        };
        time = {
          morning = "07:00";
          evening = "19:00";
        };
        transitionTime = 15;
      };
    };
    #kscreenlocker = {
    #  appearance = {
    #    wallpaperSlideShow = {
    #      path = "/home/chris/nixos-configs/home/chris/wallpaper/";
    #    };
    #  };
    #};
    workspace = {
      wallpaperSlideShow = {
        path = "/home/chris/nixos-configs/home/chris/wallpaper/";
      };
      cursor = {
        theme = "WhiteSur-cursors";
        size = 24;
      };
      clickItemTo = "open";
      lookAndFeel = "org.kde.breezedark.desktop";
    };
    configFile = {
      #"kcminputrc"."Libinput/5426/154/Razer ProClickM"."PointerAcceleration" = "-0.400"; # set mouse speed
    };
    #iconTheme = "Papirus-Dark";
    };

}
