{ 
  config,
  lib,
  configLib,
  pkgs, 
  ... 
}: 

{

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "home-manager/chris/common/alacritty.nix"
      #"home-manager/chris/common/gammastep.nix"
      "home-manager/chris/common/vscodium.nix"
      "home-manager/chris/common/firefox.nix"
      #"home-manager/chris/common/theme.nix"
      #"home-manager/chris/common/rofi.nix"
    ])
  ];

  home.packages = with pkgs; [
    libreoffice-still # office suite
    element-desktop # matrix chat app
    nextcloud-client # nextcloud local syncronization client
  ];

  services.gpg-agent = {
    pinentry.package = lib.mkForce pkgs.kwalletcli;
    extraConfig = "pinentry-program ${pkgs.kwalletcli}/bin/pinentry-kwallet"; # set kde wallet as pinentry utility
  };

  programs.plasma = {
    enable = true;
    overrideConfig = true;
    
    fonts = {
      fixedWidth = {
        family = "JetBrainsMono Nerd Font Mono";
        pointSize = 11;
      };
      general = {
        family = "Roboto";
        pointSize = 11;
      };
      menu = {
        family = "Roboto";
        pointSize = 11;
      };
      small = {
        family = "Roboto";
        pointSize = 8;
      };
      toolbar = {
        family = "Roboto";
        pointSize = 11;
      };
      windowTitle = {
        family = "Roboto";
        pointSize = 11;
      };
    };

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

    hotkeys.commands = {
      clear-notifications = {
        name = "Clear all KDE Plasma notifications";
        key = "Meta+Shift+Backspace";
        command = "clear-kde-notifications";
      };
      launch-alacritty = {
        name = "Launch Alacritty";
        key = "Meta+Shift+Return";
        command = "alacritty";
      };
      #screenshot-region = {
      #  name = "Capture a rectangular region of the screen";
      #  key = "Meta+Shift+S";
      #  command = "spectacle --region --nonotify";
      #};
      #screenshot-screen = {
      #  name = "Capture the entire desktop";
      #  key = "Meta+Ctrl+S";
      #  command = "spectacle --fullscreen --nonotify";
      #};
    };

    kwin = {

      effects = {
        blur.enable = false;
        cube.enable = false;
        desktopSwitching.animation = "off";
        dimAdminMode.enable = false;
        dimInactive.enable = false;
        fallApart.enable = false;
        fps.enable = false;
        minimization.animation = "off";
        shakeCursor.enable = false;
        slideBack.enable = false;
        snapHelper.enable = false;
        translucency.enable = false;
        windowOpenClose.animation = "off";
        wobblyWindows.enable = false;
      };

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

      virtualDesktops = {
        number = 5;
        rows = 1;
      };

    };

    session = {
      general.askForConfirmationOnLogout = false;
      sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
    };

    shortcuts = {

      #ksmserver = {
      #  "Lock Session" = [
      #    "Screensaver"
      #    "Ctrl+Alt+L"
      #  ];
      #  "LogOut" = [
      #    "Ctrl+Alt+Q"
      #  ];
      #};

      kwin = {
        "Switch to Desktop 1" = "Meta+1";
        "Switch to Desktop 2" = "Meta+2";
        "Switch to Desktop 3" = "Meta+3";
        "Switch to Desktop 4" = "Meta+4";
        "Switch to Desktop 5" = "Meta+5";
        "Switch to Desktop 6" = "Meta+6";
        "Switch to Desktop 7" = "Meta+7";
        "Window Close" = "Meta+Q";
        "Window Fullscreen" = "Meta+F";
      };

      #plasmashell = {
      #  "show-on-mouse-pos" = "";
      #};

    };

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
      "kwinrc"."Windows"."Placement" = "Maximizing"; # automatically open all windows maximized by default
    };
    #iconTheme = "Papirus-Dark";
    };

}
