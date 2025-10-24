{ 
  config,
  configVars,
  #osConfig,
  lib,
  configLib,
  pkgs, 
  ... 
}: 

# run "nix shell nixpkgs#nix-prefetch-github -c nix-prefetch-github dc-bond nixos-configs --rev main" to get rev and hash for most recent main branch
let
  wallpaperRepo = pkgs.fetchFromGitHub {
    owner = "dc-bond";
    repo = "nixos-configs";
    rev = "c832b826a616ea800d29948c38967aa193a31bb1";
    sparseCheckout = [ "wallpaper" ];
    hash = "sha256-qb6KxcuxMJxcG4KbGH2yMbqJDbGMlSF6KxuWtaPKofs=";
  };
  #krfbPasswdPath = osConfig.sops.templates."krfbPasswd".path;
in

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
    whitesur-cursors # cursor theme
    trayscale # tailscale tray applet
    ktailctl # tailscale tray applet
    iwgtk # tray applet for wifi
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
        hiding = "autohide";
        widgets = [
          {
            kickoff = {
              icon = "arrow-up-double"; 
              sortAlphabetically = true;
              compactDisplayStyle = true;
              favoritesDisplayMode = "list";
              applicationsDisplayMode = "list";
              #settings = {
              #  General = {
              #    favorites = "chromium-browser.desktop,org.kde.dolphin.desktop,Alacritty.desktop";
              #    showRecentApps = false;
              #    showRecentDocs = false;
              #    showRecentContacts = false;
              #  };
              #};
            };
          }
          "org.kde.plasma.panelspacer" # everything subsequent is moved to the right of the panel
          "org.kde.plasma.systemtray"
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
      wallpaperSlideShow.path = "${wallpaperRepo}/wallpaper";
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

  };

  systemd.user.services = {
    #krfb-config-setup = {
    #  Unit = {
    #    Description = "Setup krfb configuration with password from sops";
    #    Before = [ "krfb.service" ];
    #  };
    #  Service = {
    #    Type = "oneshot";
    #    RemainAfterExit = true;
    #    ExecStart = pkgs.writeShellScript "krfb-config-setup" ''
    #      set -e
    #      
    #      if [ ! -f "${krfbPasswdPath}" ]; then
    #        echo "error: password secret not found at ${krfbPasswdPath}"
    #        exit 1
    #      fi
    #      
    #      PASSWORD=$(cat "${krfbPasswdPath}")
    #      
    #      mkdir -p ${config.home.homeDirectory}/.config
    #      cat > ${config.home.homeDirectory}/.config/krfbrc << EOF
    #      [FrameBuffer]
    #      preferredFrameBufferPlugin=pw

    #      [Security]
    #      allowUnattendedAccess=true
    #      allowUninvitedConnections=true
    #      askOnConnect=false
    #      desktopPassword=$PASSWORD
    #      noWallet=true
    #      unattendedPassword=$PASSWORD
    #      
    #      EOF
    #      
    #      chmod 600 ${config.home.homeDirectory}/.config/krfbrc
    #      echo "krfb configuration created successfully"
    #    '';
    #  };
    #  Install.WantedBy = [ "graphical-session.target" ];
    #};
    #krfb = {
    #  Unit = {
    #    Description = "KDE Remote Frame Buffer Server";
    #    After = [ "graphical-session.target" "krfb-config-setup.service" ];
    #    Requires = [ "krfb-config-setup.service" ];
    #    PartOf = [ "graphical-session.target" ];
    #  };
    #  Service = {
    #    Type = "simple";
    #    ExecStart = "${pkgs.kdePackages.krfb}/bin/krfb --nodialog";
    #    Restart = "on-failure";
    #    RestartSec = "5s";
    #    PrivateTmp = true;
    #    NoNewPrivileges = true;
    #  };
    #  Install = {
    #    WantedBy = [ "graphical-session.target" ];
    #  };
    #};
    krdp = {
      Unit = {
        Description = "Plasma Remote Desktop (RDP)";
        After = [ "plasma-workspace.target" "pipewire.service" ];
        PartOf = [ "plasma-workspace.target" ];
      };
      Service = {
        ExecStart = "${pkgs.kdePackages.krdp}/bin/krdp";
        Restart = "on-failure";
        Slice = "session.slice";
      };
      Install = {
        WantedBy = [ "plasma-workspace.target" ];
      }; 
    };
    tailscale-operator = {
      Unit = {
        Description = "Configure tailscale for tray applet";
        After = [ "tailscaled.service" "network-online.target" ];
        Wants = [ "tailscaled.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.tailscale}/bin/tailscale set --operator=${configVars.chrisUsername}";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };

}