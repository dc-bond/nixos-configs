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
      #    acceleration = 0.5;
      #    accelerationProfile = "none";
      #    enable = true;
      #    leftHanded = false;
      #    middleButtonEmulation = false;
      #    name = "Logitech G403 HERO Gaming Mouse";
      #    naturalScroll = false;
      #    productId = "c08f";
      #    scrollSpeed = 1;
      #    vendorId = "046d";
      #  }
      #]
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
      "kcminputrc"."Libinput/5426/154/Razer ProClickM"."PointerAcceleration" = "-0.400"; # set mouse speed
      "kdeglobals"."General"."font" = "SauceCodePro Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
      "kdeglobals"."General"."menuFont" = "SauceCodePro Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
      "kdeglobals"."General"."toolBarFont" = "SauceCodePro Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
      "kwalletrc"."Wallet"."First Use" = false; # specify kwallet already has run
    };
    #iconTheme = "Papirus-Dark";
    };

}
