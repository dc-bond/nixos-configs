{ 
  pkgs,
  config,
  ... 
}: 

{

  services.greetd = {
    enable = true;
    settings = {
      default_session.command = ''
        ${pkgs.greetd.tuigreet}/bin/tuigreet \
          --time \
          --time-format '%a, %d %b %Y • %H:%M' \
          --asterisks \
          --theme 'border=blue;text=white;prompt=cyan;time=green;action=magenta;button=yellow' \
          --greeting 'Access is restricted to authorized personnel only.' \
          --user-menu \
          --remember \
          --remember-user-session \
          --cmd startplasma-wayland
      '';
    };
  };

  environment.etc."greetd/environments".text = ''
    Hyprland
    startplasma-wayland
    zsh
  '';

}
