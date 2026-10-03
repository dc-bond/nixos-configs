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
    # start-hyprland is a watchdog that execs Hyprland; 0.55 warns on screen when
    # launched without it. it resolves Hyprland from PATH, so the security.wrappers
    # copy carrying cap_sys_nice is still what gets run
    thinkpad = "start-hyprland";
    cypress = "start-hyprland";
    alder = "labwc"; # deprecated host, not deployed
    kauri = "labwc";
  };
  defaultCmd = defaultCmdByHost.${config.networking.hostName} or "zsh";
in

{

  services.greetd = {
    enable = true;
    settings = {
      # tuigreet 0.11 no longer bounds the user menu by /etc/login.defs, so the 32
      # nixbld accounts at 30001+ show up alongside real users; the bounds below
      # are login.defs' own UID_MIN/UID_MAX
      default_session.command = ''
        ${pkgs.tuigreet}/bin/tuigreet \
          --time \
          --time-format '%a, %d %b %Y • %H:%M' \
          --asterisks \
          --theme "border=white;text=white;prompt=white;time=green;action=green;button=white" \
          --greeting "Access is restricted to authorized personnel only." \
          --user-menu \
          --user-menu-min-uid 1000 \
          --user-menu-max-uid 29999 \
          --remember \
          --remember-user-session \
          --sessions ${customSessions}/share/wayland-sessions:/run/current-system/sw/share/wayland-sessions \
          --xsessions /dev/null \
          --cmd ${defaultCmd}
      '';
    };
  };

}