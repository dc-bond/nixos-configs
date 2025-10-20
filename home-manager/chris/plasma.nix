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

  services.gpg-agent.pinentry.package = pkgs.pinentry-qt;

  # Hide applications from launcher
  xdg.dataFile = {
    "applications/org.kde.kinfocenter.desktop".text = ''
      [Desktop Entry]
      NoDisplay=true
    '';
    "applications/org.kde.plasma-systemmonitor.desktop".text = ''
      [Desktop Entry]
      NoDisplay=true
    '';
    "applications/org.kde.ksystemlog.desktop".text = ''
      [Desktop Entry]
      NoDisplay=true
    '';
    # Add more as needed - check ~/.local/share/applications/ and /run/current-system/sw/share/applications/
  };

  programs.plasma = {
    enable = true;
    overrideConfig = true;
    
    fonts = {
      fixedWidth = {
        family = "Source Code Pro";
        pointSize = 11;
      };
      general = {
        family = "Source Sans Pro";
        pointSize = 11;
      };
      menu = {
        family = "Source Sans Pro";
        pointSize = 11;
      };
      small = {
        family = "Source Sans Pro";
        pointSize = 8;
      };
      toolbar = {
        family = "Source Sans Pro";
        pointSize = 11;
      };
      windowTitle = {
        family = "Source Sans Pro";
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

    panels = [
      {
        location = "bottom";
        height = 48;
        widgets = [
          {
            name = "org.kde.plasma.kickoff";
            config.General.icon = "start-here-kde";
          }
          "org.kde.plasma.panelspacer"
          {
            name = "org.kde.plasma.icontasks";
            config.General = {
              launchers = [
                "applications:firefox.desktop"
                "applications:libreoffice-startcenter.desktop"
              ];
            };
          }
          "org.kde.plasma.panelspacer"
          {
            name = "org.kde.plasma.systemtray";
            config.General.scaleIconsToFit = true;
          }
          {
            name = "org.kde.plasma.digitalclock";
            config.Appearance = {
              showDate = true;
              use24hFormat = true;
            };
          }
        ];
      }
    ];


    hotkeys.commands = {
      #clear-notifications = {
      #  name = "Clear all KDE Plasma notifications";
      #  key = "Meta+Shift+Backspace";
      #  command = "clear-kde-notifications";
      #};
      launch-alacritty = {
        name = "Launch Alacritty";
        key = "Alt+Return";
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
        number = 1;
        rows = 1;
      };
    };

    session = {
      general.askForConfirmationOnLogout = false;
      sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
    };

    shortcuts = {
      kwin = {
        "Window Close" = "Alt+q";
        "Window Fullscreen" = "Alt+f";
      };
    };

    workspace = {
      wallpaperSlideShow = {
        path = "/home/chris/nixos-configs/home/chris/wallpaper/";
      };
      cursor = {
        theme = "WhiteSur-cursors";
        size = 20;
      };
      clickItemTo = "open";
      lookAndFeel = "org.kde.breeze.desktop";
    };

    configFile = {
      "kwinrc"."Windows"."Placement" = "Maximizing"; # automatically open all windows maximized by default
      "kdeglobals"."KDE"."ShowDeleteCommand" = false; # hode menu configuration options in applications
    };

  };

}