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
          --asterisks \
          --user-menu \
          --remember \
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
