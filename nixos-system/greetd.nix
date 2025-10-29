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
in

{

  services.greetd = {
    enable = true;
    #settings = {
    #  default_session.command = ''
    #    command = "${pkgs.cage}/bin/cage -s -m last -- ${pkgs.greetd.regreet}/bin/regreet";
    #    user = "greeter";
    #  '';
    #};
  };

  programs.regreet.enable = true;

}

  #services.greetd = {
  #  enable = true;
  #  settings = {
  #    default_session.command = ''
  #      ${pkgs.greetd.tuigreet}/bin/tuigreet \
  #        --time \
  #        --time-format '%a, %d %b %Y • %H:%M' \
  #        --asterisks \
  #        --theme "border=blue;text=white;prompt=cyan;time=green;action=green;button=yellow" \
  #        --greeting "Access is restricted to authorized personnel only." \
  #        --user-menu \
  #        --remember \
  #        --remember-user-session \
  #        --sessions ${customSessions}/share/wayland-sessions:/run/current-system/sw/share/wayland-sessions \
  #        --xsessions /dev/null \
  #        --cmd startplasma-wayland
  #    '';
  #  };
  #};