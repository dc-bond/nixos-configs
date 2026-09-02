{ 
  inputs, 
  config,
  lib,
  configLib,
  pkgs, 
  osConfig,
  ... 
}: 

let
  username = builtins.baseNameOf ./.;
in

{

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "home-manager/shared/alacritty.nix"
      "home-manager/shared/desktop-plumbing.nix"
      "home-manager/shared/rofi.nix"
      "home-manager/shared/waybar.nix"
      "home-manager/shared/gammastep.nix"
      "home-manager/shared/chromium.nix"
      "home-manager/shared/firefox.nix"
      "home-manager/${username}/vscodium.nix"
    ])
  ];

  home = {
    packages = with pkgs; [
      libreoffice-qt6 # office suite (qt6 for native wayland support)
      element-desktop # matrix chat app
      nextcloud-client # nextcloud local syncronization client
    ];
    pointerCursor = {
      enable = true;
      name = "WhiteSur-cursors";
      package = pkgs.whitesur-cursors;
      size = 20;
      gtk.enable = true; # integrate with gtk apps
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Materia-light";
      package = pkgs.materia-theme;
    };
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-nord;
    };
    font = {
      name = "Source Sans Pro";
      package = null; # already installed in fonts.nix system-level module
      size = 10;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = false;  # since using materia light
      gtk-decoration-layout = "menu:minimize,maximize,close";
    };
    gtk4.extraConfig = {
      gtk-decoration-layout = "menu:minimize,maximize,close";
    };
  };
  
  # override element desktop entry to specify keyring backend
  xdg.desktopEntries.element-desktop = {
    name = "Element";
    exec = "element-desktop --password-store=gnome-libsecret %u";
    icon = "element";
    type = "Application";
    categories = [ "Network" "InstantMessaging" "Chat" ];
    mimeType = [ "x-scheme-handler/element" ];
  };

  xdg.configFile = {

    "labwc/rc.xml".text = ''
      <?xml version="1.0"?>
      <labwc_config>

        <core>
          <decoration>server</decoration>
          <windowSwitcher show="yes" preview="yes" outlines="yes" />
        </core>
        
        <theme>
          <name>Materia-light</name>
          <cornerRadius>5</cornerRadius>
        </theme>

        <windowRules>
          <windowRule identifier="*">
            <action name="Maximize"/>
          </windowRule>
        </windowRules>

        <keyboard>
          <numlock>yes</numlock>
          <repeatRate>35</repeatRate>
          <repeatDelay>200</repeatDelay>
          
          <keybind key="A-Return">
            <action name="Execute" command="alacritty" />
          </keybind>
          
          <keybind key="A-d">
            <action name="Execute" command="rofi -show drun" />
          </keybind>

          <keybind key="A-b">
            <action name="Execute" command="rofi-bluetooth" />
          </keybind>

          <keybind key="A-c">
            <action name="Execute" command="rofi -show calc -modi calc -no-show-match -no-sort" />
          </keybind>

          <keybind key="A-Tab">
            <action name="PreviousWindow" />
          </keybind>

          <keybind key="A-backslash">
            <action name="NextWindow" />
          </keybind>

          <keybind key="A-q">
            <action name="Close" />
          </keybind>
          
          <keybind key="A-f">
            <action name="ToggleFullscreen" />
          </keybind>
          
          <keybind key="A-t">
            <action name="ToggleDecorations" />
          </keybind>
          
          <keybind key="A-F8">
            <action name="Execute" command="rfkill toggle wlan" />
          </keybind>

          <keybind key="F5">
            <action name="Execute" command="brightnessctl set 10%-" />
          </keybind>

          <keybind key="F6">
            <action name="Execute" command="brightnessctl set +10%" />
          </keybind>
          
          <keybind key="Print">
            <action name="Execute" command="hyprshot -m region output --clipboard-only" />
          </keybind>
        </keyboard>
        
        <mouse>
          <default />
          <context name="Frame">
            <mousebind button="A-Right" action="Drag">
              <action name="Resize" />
            </mousebind>
          </context>
          <context name="Title">
            <mousebind button="Left" action="DoubleClick">
              <action name="ToggleMaximize" />
            </mousebind>
          </context>
          <context name="Root">
            <mousebind button="Left" action="Press" />
            <mousebind button="Right" action="Press">
              <action name="ShowMenu" menu="root-menu" />
            </mousebind>
          </context>
          <context name="Client">
            <mousebind button="A-Right" action="Press">
              <action name="ShowMenu" menu="root-menu" />
            </mousebind>
          </context>
        </mouse>

        <desktops number="1" />

      </labwc_config>
    '';
    
    "labwc/menu.xml".text = ''
      <?xml version="1.0"?>
      <openbox_menu>
        <menu id="root-menu" label="labwc">
          <item label="Terminal">
            <action name="Execute" command="alacritty" />
          </item>
          <item label="Web Browser">
            <action name="Execute" command="chromium" />
          </item>
          <item label="Secure Messaging">
            <action name="Execute" command="element-desktop --password-store=gnome-libsecret" />
          </item>
          <item label="Calculator">
            <action name="Execute" command="gnome-calculator" />
          </item>
          <item label="File Manager">
            <action name="Execute" command="thunar" />
          </item>
          <item label="Office Suite">
            <action name="Execute" command="libreoffice" />
          </item>
          <item label="Code Editor">
            <action name="Execute" command="codium" />
          </item>
          <separator />
          <item label="Reload Wallpaper">
            <action name="Execute" command="desktopReload" />
          </item>
          <separator />
          <menu id="power-menu" label="Exit">
            <item label="Suspend">
              <action name="Execute" command="systemctl suspend" />
            </item>
            <item label="Logout">
              <action name="Execute" command="${pkgs.labwc}/bin/labwc --exit" />
            </item>
            <item label="Reboot">
              <action name="Execute" command="systemctl reboot" />
            </item>
            <item label="Shutdown">
              <action name="Execute" command="systemctl poweroff" />
            </item>
          </menu>
        </menu>
      </openbox_menu>
    '';

    "labwc/autostart" = {
      text = ''
        #!/bin/sh
        systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE PATH
        dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE PATH
        systemctl --user start wayvnc.service
        swww-daemon &
        sleep 1
        desktopReload
        sleep 1
        nextcloud
      '';
      executable = true;
    }; 
    
    "labwc/environment".text = ''
      XDG_CURRENT_DESKTOP=labwc
      XDG_SESSION_TYPE=wayland
      QT_QPA_PLATFORM=wayland
      QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    '';
  };
  
}
