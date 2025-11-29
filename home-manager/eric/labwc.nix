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
  wallpaperDir = pkgs.runCommand "wallpapers" {} ''
    mkdir -p $out
    cp -r ${inputs.self}/wallpaper/* $out/
  '';
  desktopReloadScript = pkgs.writeShellScriptBin "desktopReload" ''
    # select random wallpaper and create color scheme
    wal -s -t -q -i ${wallpaperDir}
    
    # load current pywal color scheme
    source "$HOME/.cache/wal/colors.sh"
    
    # copy color file to waybar folder
    cp ~/.cache/wal/colors-waybar.css ~/.config/waybar/
    cp $wallpaper ~/.cache/current_wallpaper.jpg
    
    # get wallpaper image name
    newwall=$(echo $wallpaper | sed "s|~/nixos-configs/wallpaper/||g")
    
    # set the new wallpaper
    swww img $wallpaper --transition-step 20 --transition-fps=20
    
    # reload waybar
    pkill waybar
    waybar &
    
    # send notification
    dunstify "wallpaper updated with image $newwall"
  '';
in

{

  imports = lib.flatten [
    (map configLib.relativeToRoot [
      "home-manager/shared/alacritty.nix"
      "home-manager/shared/rofi.nix"
      "home-manager/shared/waybar.nix"
      "home-manager/shared/hyprlock.nix"
      "home-manager/shared/gammastep.nix"
      "home-manager/${username}/firefox.nix"
    ])
  ];

  home.packages = with pkgs; [
    desktopReloadScript
    swww # animated wallpaper for wayland window managers
    pywal # color theme changer
    dunst # notification daemon
    grim # screenshot tool
    wlr-randr # output management
    gnome-calculator # calculator
    loupe # image viewer
    zathura # barebones pdf viewer
    hyprshot # screenshot tool
    pwvucontrol # pipewire audio volume control app
    #nwg-menu
  ];

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
    };
  };

  xdg.configFile = {

    #"nwg-menu/appendix".text = ''
    #  Terminal; alacritty; utilities-terminal
    #  Firefox; firefox-esr; firefox
    #  Calculator; gnome-calculator; accessories-calculator
    #  File Manager; thunar; system-file-manager
    #  Reload Wallpaper; desktopReload; preferences-desktop-wallpaper
    #  Lock Screen; hyprlock; system-lock-screen
    #  Exit; ${pkgs.wlogout}/bin/wlogout; system-shutdown
    #'';

    "labwc/rc.xml".text = ''
      <?xml version="1.0"?>
      <labwc_config>

        <core>
          <decoration>server</decoration>
        </core>
        
        <theme>
          <name>Materia-light</name>
          <cornerRadius>5</cornerRadius>
        </theme>

        <windowRules>
          <windowRule>
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
            <action name="Execute" command="rofi -modes run,ssh -show run" />
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

          <keybind key="A-F11">
            <action name="Execute" command="brightnessctl set 10%-" />
          </keybind>
          
          <keybind key="A-F12">
            <action name="Execute" command="brightnessctl set +10%" />
          </keybind>
          
          <keybind key="A-S-q">
            <action name="Execute" command="${pkgs.wlogout}/bin/wlogout" />
          </keybind>
          
          <keybind key="Print">
            <action name="Execute" command="hyprshot -m region output --clipboard-only" />
          </keybind>
        </keyboard>
        
        <mouse>
          <default />
          <context name="Frame">
            <mousebind button="A-Left" action="Drag">
              <action name="Move" />
            </mousebind>
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
            <mousebind button="Right" action="Press">
              <action name="ShowMenu" menu="root-menu" />
            </mousebind>
          </context>
        </mouse>

        <context name="Client">
          <mousebind button="A-Right" action="Press">
            <action name="ShowMenu" menu="root-menu" />
          </mousebind>
        </context>
        
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
          <item label="Firefox">
            <action name="Execute" command="firefox-esr" />
          </item>
          <item label="Calculator">
            <action name="Execute" command="gnome-calculator" />
          </item>
          <item label="File Manager">
            <action name="Execute" command="thunar" />
          </item>
          <separator />
          <item label="Reload Wallpaper">
            <action name="Execute" command="desktopReload" />
          </item>
          <separator />
          <item label="Lock Screen">
            <action name="Execute" command="hyprlock" />
          </item>
          <item label="Exit">
            <action name="Execute" command="${pkgs.wlogout}/bin/wlogout" />
          </item>
        </menu>
      </openbox_menu>
    '';
    
    "labwc/autostart" = {
      text = ''
        #!/bin/sh
        swww-daemon &
        dunst &
        sleep 2 && desktopReload &
      '';
      executable = true;
    };
    
    "labwc/environment".text = ''
      XDG_CURRENT_DESKTOP=labwc
      XDG_SESSION_TYPE=wayland
      MOZ_ENABLE_WAYLAND=1
      QT_QPA_PLATFORM=wayland
      QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    '';
  };
  
}