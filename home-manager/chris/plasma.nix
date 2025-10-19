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
      "home-manager/chris/alacritty.nix"
      "home-manager/chris/vscodium.nix"
      "home-manager/chris/firefox.nix"
    ])
  ];

  home.packages = with pkgs; [
    libreoffice-still # office suite
    element-desktop # matrix chat app
    nextcloud-client # nextcloud local syncronization client
  ];

  #services.gpg-agent = {
  #  pinentry.package = lib.mkForce pkgs.kwalletcli;
  #  extraConfig = "pinentry-program ${pkgs.kwalletcli}/bin/pinentry-kwallet"; # set kde wallet as pinentry utility
  #};

  services.gpg-agent.pinentryPackage = lib.mkForce pkgs.pinentry-qt;

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
      "kwinrc"."Windows"."Placement" = "Maximizing"; # automatically open all windows maximized by default
    };

  };

}

#{ 
#  config,
#  lib,
#  pkgs, 
#  ... 
#}: 
#
#{
#
#  home.packages = with pkgs; [
#    libreoffice-still
#    firefox # or whatever browser you prefer
#    # That's it! Keep it minimal
#  ];
#
#  programs.plasma = {
#    enable = true;
#    overrideConfig = true;
#    
#    # Simple, readable fonts
#    fonts = {
#      general = {
#        family = "Noto Sans";
#        pointSize = 11;
#      };
#    };
#
#    # Basic input settings
#    input.keyboard = {
#      numlockOnStartup = "on";
#    };
#
#    # Minimal panel configuration
#    panels = [
#      {
#        location = "bottom";
#        height = 48;
#        widgets = [
#          {
#            name = "org.kde.plasma.kickoff";
#            config.General.icon = "start-here-kde";
#          }
#          "org.kde.plasma.panelspacer"
#          {
#            name = "org.kde.plasma.icontasks";
#            config.General = {
#              launchers = [
#                "applications:firefox.desktop"
#                "applications:libreoffice-startcenter.desktop"
#              ];
#            };
#          }
#          "org.kde.plasma.panelspacer"
#          {
#            name = "org.kde.plasma.systemtray";
#            config.General.scaleIconsToFit = true;
#          }
#          {
#            name = "org.kde.plasma.digitalclock";
#            config.Appearance = {
#              showDate = true;
#              use24hFormat = true;
#            };
#          }
#        ];
#      }
#    ];
#
#    # Disable all eye candy
#    kwin.effects = {
#      blur.enable = false;
#      cube.enable = false;
#      desktopSwitching.animation = "off";
#      dimAdminMode.enable = false;
#      dimInactive.enable = false;
#      fallApart.enable = false;
#      minimization.animation = "off";
#      shakeCursor.enable = false;
#      slideBack.enable = false;
#      snapHelper.enable = false;
#      translucency.enable = false;
#      windowOpenClose.animation = "off";
#      wobblyWindows.enable = false;
#    };
#
#    # Single desktop, no virtual desktops
#    kwin.virtualDesktops = {
#      number = 1;
#      rows = 1;
#    };
#
#    # Simple session behavior
#    session = {
#      general.askForConfirmationOnLogout = false;
#      sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
#    };
#
#    # Essential shortcuts only
#    shortcuts.kwin = {
#      "Window Close" = "Alt+F4"; # Standard, familiar
#    };
#
#    # Clean, simple appearance
#    workspace = {
#      cursor = {
#        theme = "breeze_cursors";
#        size = 24;
#      };
#      clickItemTo = "open";
#      lookAndFeel = "org.kde.breeze.desktop"; # Light theme, less intimidating
#      # Or use "org.kde.breezedark.desktop" if preferred
#    };
#
#    # Maximize windows by default - simpler for basic users
#    configFile = {
#      "kwinrc"."Windows"."Placement" = "Maximizing";
#    };
#
#    # Hide menu configuration options in applications
#    configFile."kdeglobals"."KDE"."ShowDeleteCommand" = false;
#    
#  };
#
#  # Hide applications from launcher
#  xdg.dataFile = {
#    # Hide all the system/settings apps that might still appear
#    "applications/org.kde.kinfocenter.desktop".text = ''
#      [Desktop Entry]
#      NoDisplay=true
#    '';
#    "applications/org.kde.plasma-systemmonitor.desktop".text = ''
#      [Desktop Entry]
#      NoDisplay=true
#    '';
#    "applications/org.kde.ksystemlog.desktop".text = ''
#      [Desktop Entry]
#      NoDisplay=true
#    '';
#    # Add more as needed - check ~/.local/share/applications/ and /run/current-system/sw/share/applications/
#  };
#
#}
