{ 
  pkgs,
  config,
  ... 
}: 

let
  customSessions = pkgs.runCommand "custom-wayland-sessions" {} ''
    mkdir -p $out/share/wayland-sessions
    cat > $out/share/wayland-sessions/zsh.desktop <<EOF
    [Desktop Entry]
    Name=Zsh (Console)
    Exec=zsh
    Type=Application
    EOF
  '';
  defaultCmdByHost = {
    thinkpad = "startplasma-wayland";
    alder = "labwc";
    cypress = "Hyprland";
  };
  defaultCmd = defaultCmdByHost.${config.networking.hostName} or "zsh";
in

{

  services.greetd = {
    enable = true;
    vt = 2; # move to vt 2 to avoid long-running boot messages glitching tuigreet
    settings = {
      default_session.command = ''
        ${pkgs.greetd.tuigreet}/bin/tuigreet \
          --time \
          --time-format '%a, %d %b %Y • %H:%M' \
          --asterisks \
          --theme "border=white;text=white;prompt=white;time=green;action=green;button=white" \
          --greeting "Access is restricted to authorized personnel only." \
          --user-menu \
          --remember \
          --remember-user-session \
          --sessions ${customSessions}/share/wayland-sessions:/run/current-system/sw/share/wayland-sessions \
          --xsessions /run/current-system/sw/share/xsessions \
          --cmd ${defaultCmd}
      '';
          #--xsessions /dev/null \
    };
  };

}