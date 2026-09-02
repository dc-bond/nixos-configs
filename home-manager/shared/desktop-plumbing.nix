{ 
  inputs,
  pkgs, 
  ... 
}: 

# desktop furniture shared by every graphical user regardless of compositor: the wallpaper/
# theme cycling script and its timer, plus the handful of apps a session needs to be usable
# (notifications, screenshot, volume, calculator, image and pdf viewer). nothing here is
# account-bound or compositor-specific — per-person apps (nextcloud-client, element-desktop,
# libreoffice) and remote-access clients stay in the per-user compositor module

let

  wallpaperDir = pkgs.runCommand "wallpapers" {} ''
    mkdir -p $out
    cp -r ${inputs.self}/wallpaper/* $out/
  '';

  desktopReloadScript = pkgs.writeShellScriptBin "desktopReload" ''
    # select random wallpaper and create color scheme
    ${pkgs.pywal}/bin/wal -s -t -q -i ${wallpaperDir}

    # load current pywal color scheme
    source "$HOME/.cache/wal/colors.sh"

    # copy color file to waybar folder
    ${pkgs.coreutils}/bin/cp ~/.cache/wal/colors-waybar.css ~/.config/waybar/
    ${pkgs.coreutils}/bin/cp $wallpaper ~/.cache/current_wallpaper.jpg

    # set the new wallpaper
    ${pkgs.swww}/bin/swww img $wallpaper --transition-step 20 --transition-fps=20

    # reload waybar
    ${pkgs.procps}/bin/pkill waybar || true
    ${pkgs.waybar}/bin/waybar &

    # send notification
    #${pkgs.dunst}/bin/dunstify "Wallpaper and Taskbar Reloaded"
  '';

in

{

  home.packages = [ desktopReloadScript ] ++ (with pkgs; [
    swww # animated wallpaper for wayland window managers
    pywal # color theme changer
    dunst # notification daemon
    gnome-calculator # calculator
    loupe # image viewer
    zathura # barebones pdf viewer
    hyprshot # screenshot tool
    pwvucontrol # pipewire audio volume control app
  ]);

  # wrap desktopReload in a systemd user service so timer can automatically cycle wallpaper, otherwise desktopReload called directly from startup script and hotkeys
  systemd.user = {
    services.desktopReload = {
      Unit = {
        Description = "Reload desktop theme and wallpaper";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${desktopReloadScript}/bin/desktopReload";
        KillMode = "process"; # don't kill backgrounded waybar when script exits
      };
    };
    timers.desktopReload = {
      Unit = {
        Description = "Desktop reload timer";
      };
      Timer = {
        OnCalendar = "hourly";
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };

}
