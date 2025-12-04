{ 
  inputs,
  config,
  configVars,
  lib,
  configLib,
  pkgs, 
  ... 
}: 

let
  username = builtins.baseNameOf ./.;
  wallpaperDir = pkgs.runCommand "wallpapers" {} ''
    mkdir -p $out
    cp -r ${inputs.self}/wallpaper/* $out/
  '';
in

{

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "home-manager/${username}/alacritty.nix"
      "home-manager/${username}/vscodium.nix"
      "home-manager/${username}/firefox.nix"
    ])
  ];

  home.packages = with pkgs; [
    libreoffice-still # office suite
    element-desktop # matrix chat app
    nextcloud-client # nextcloud local syncronization client
    whitesur-cursors # cursor theme
  ];

  services.gpg-agent.pinentry.package = pkgs.pinentry-qt;

  xdg.dataFile = {
    "applications/org.kde.kinfocenter.desktop".text = ''
      [Desktop Entry]
      NoDisplay=true
    '';
    "applications/org.kde.kmenuedit.desktop".text = ''
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
    "applications/systemsettings.desktop".text = ''
      [Desktop Entry]
      NoDisplay=true
    '';
    "applications/kdesystemsettings.desktop".text = ''
      [Desktop Entry]
      NoDisplay=true
    '';
      "applications/nixos-manual.desktop".text = ''
      [Desktop Entry]
      NoDisplay=true
    '';
    "applications/org.freedesktop.IBus.Setup.desktop".text = ''
      [Desktop Entry]
      NoDisplay=true
    '';
    "applications/org.freedesktop.IBus.Panel.Emojier.desktop".text = ''
      [Desktop Entry]
      NoDisplay=true
    '';
    "applications/org.freedesktop.IBus.Panel.Extension.Gtk3.desktop".text = ''
      [Desktop Entry]
      NoDisplay=true
    '';
    "applications/org.freedesktop.IBus.Panel.Wayland.Gtk3.desktop".text = ''
      [Desktop Entry]
      NoDisplay=true
    '';
    "applications/org.kde.drkonqi.desktop".text = ''
      [Desktop Entry]
      NoDisplay=true
    '';
    "applications/org.kde.drkonqi.coredump.gui.desktop".text = ''
      [Desktop Entry]
      NoDisplay=true
    '';
    "applications/org.kde.plasma.emojier.desktop".text = ''
      [Desktop Entry]
      NoDisplay=true
    '';
    "applications/cups.desktop".text = ''
      [Desktop Entry]
      NoDisplay=true
    '';
    "applications/nvim.desktop".text = ''
      [Desktop Entry]
      NoDisplay=true
    '';
  };

  programs.plasma = {
    enable = true;
    overrideConfig = true;
    
    fonts = {
      fixedWidth = {
        family = "Source Code Pro";
        pointSize = 10;
      };
      general = {
        family = "Source Sans Pro";
        pointSize = 10;
      };
      menu = {
        family = "Source Sans Pro";
        pointSize = 10;
      };
      small = {
        family = "Source Sans Pro";
        pointSize = 8;
      };
      toolbar = {
        family = "Source Sans Pro";
        pointSize = 10;
      };
      windowTitle = {
        family = "Source Sans Pro";
        pointSize = 10;
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
        height = 30;
        #hiding = "autohide";
        widgets = [
          {
            kickoff = {
              icon = "arrow-up-double"; 
              sortAlphabetically = true;
              compactDisplayStyle = true;
              favoritesDisplayMode = "list";
              applicationsDisplayMode = "list";
              showButtonsFor = "session";
              settings = {
                General = {
                  favorites = "firefox.desktop,org.kde.dolphin.desktop,Alacritty.desktop";
                  showRecentApps = false;
                  showRecentDocs = false;
                  showRecentContacts = false;
                };
              };
            };
          }
          {
            iconTasks = {
              launchers = [ ];
            };
          }
          "org.kde.plasma.panelspacer" # everything subsequent is moved to the right of the panel
          {
            systemTray.items = {
              showAll = true;
              extra = [
                "org.kde.plasma.volume"
                #"org.kde.plasma.cameraindicator"
                "org.kde.plasma.bluetooth"
                "org.kde.plasma.battery"
                "org.kde.plasma.brightness"
                "org.kde.kscreen"
                #"org.kde.plasma.printmanager"
              ];
            };
          }
          "org.kde.plasma.digitalclock"
          "org.kde.plasma.showdesktop"
        ];
      }
    ];

    hotkeys.commands = {
      launch-alacritty = {
        name = "Launch Alacritty";
        key = "Alt+Return";
        command = "alacritty";
      };
    };

    krunner = {
      position = "top";
      shortcuts.launch = "Alt+d";
    };

    powerdevil = {
      AC = {
        powerProfile = "performance";
        powerButtonAction = "shutDown";
        autoSuspend.action = "nothing";
        turnOffDisplay.idleTimeout = "never";
        dimDisplay.enable = false;
        whenLaptopLidClosed = "doNothing";
        inhibitLidActionWhenExternalMonitorConnected = true;  # don't sleep when lid closes with external monitor
      };
      battery = {
        powerProfile = "powerSaving";
        powerButtonAction = "shutDown";
        whenSleepingEnter = "standby";
        dimDisplay.enable = false;
        autoSuspend = {
          action = "sleep";
          idleTimeout = 600;
        };
      };
      lowBattery = {
        powerProfile = "powerSaving";
        whenLaptopLidClosed = "sleep";
      };
      batteryLevels = {
        lowLevel = 10;
        criticalLevel = 2;
        criticalAction = "shutDown";
      };
    };

    kscreenlocker = {
      autoLock = false;
      lockOnResume = false;
      lockOnStartup = false;
      timeout = null;
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
      wallpaperSlideShow.path = "${wallpaperDir}";
      cursor = {
        theme = "WhiteSur-cursors";
        size = 20;
      };
      clickItemTo = "select";
      lookAndFeel = "org.kde.breeze.desktop";
    };

    configFile = {
      baloofilerc."Basic Settings"."Indexing-Enabled" = false; # turn off kde file indexer (for search, save resources)
      "kwinrc"."Windows"."Placement" = "Maximizing"; # automatically open all windows maximized by default
      "kdeglobals"."KDE"."ShowDeleteCommand" = false; # hide full on delete option in applications
      "kdeglobals"."General".TerminalApplication = "alacritty"; # set alacritty as default terminal
    };

    startup.startupScript = {
      bluetoothPowerOn = {
        text = ''
          sleep 1 
          bluetoothctl power on
        '';
        runAlways = true;
      };
      nextcloudClient = {
        text = ''
          sleep 2
          nextcloud --background &
        '';
        runAlways = true;
      };
      networkAndTailscaleCheck = {
        text = ''
          (
            sleep 3 
            
            for i in {1..10}; do
              if ${pkgs.systemd}/bin/networkctl status | grep -q "State: routable"; then
                ${pkgs.libnotify}/bin/notify-send -u normal "Network" "NETWORK CONNECTED"
                sleep 3
                
                # network up, now check Tailscale (up to 20 seconds)
                for j in {1..10}; do
                  if ${pkgs.tailscale}/bin/tailscale status >/dev/null 2>&1; then
                    ${pkgs.libnotify}/bin/notify-send -u normal "Tailscale" "TAILSCALE CONNECTED"
                    exit 0
                  fi
                  sleep 3 
                done
                
                ${pkgs.libnotify}/bin/notify-send -u critical "Tailscale" "TAILSCALE FAILURE/nCheck with Chris"
                exit 0
              fi
              sleep 3 
            done
            
            ${pkgs.libnotify}/bin/notify-send -u critical "Network" "NETWORK FAILURE\nOpen terminal and run 'wifi' to start helper script"
          ) &
        '';
        runAlways = true;
      };
    };

  };

}