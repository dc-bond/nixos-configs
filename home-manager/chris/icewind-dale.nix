{
  pkgs,
  config,
  lib,
  ...
}:

let
  gameDir = "${config.home.homeDirectory}/games/icewind-dale-ee";
  gameEntry = "${gameDir}/IcewindDale";
  iwdLauncher = pkgs.writeShellApplication {
    name = "icewind-dale";
    runtimeInputs = [ pkgs.steam-run pkgs.coreutils ];
    text = ''
      if [ ! -f "${gameEntry}" ]; then
        echo "Icewind Dale EE not found at ${gameEntry}" >&2
        echo "Extract the GoG installer into ${gameDir} first." >&2
        exit 1
      fi
      cd "${gameDir}"
      chmod +x "${gameEntry}" # beamdog ships without the +x bit (idempotent)
      # consolidate saves/config under the game dir (XDG-redirected, scoped to this process)
      mkdir -p "${gameDir}/userdata"
      export XDG_DATA_HOME="${gameDir}/userdata"
      export SDL_VIDEODRIVER=''${SDL_VIDEODRIVER:-wayland}
      exec steam-run "${gameEntry}" "$@"
    '';
  };
in

{

  home.packages = [
    pkgs.steam-run # FHS chroot providing OpenGL/SDL2/OpenAL/glibc for the beamdog binary
    iwdLauncher
  ];

  xdg.desktopEntries.icewind-dale = {
    name = "Icewind Dale: Enhanced Edition";
    comment = "Icewind Dale EE (Beamdog) via steam-run";
    exec = "${iwdLauncher}/bin/icewind-dale";
    icon = "applications-games";
    type = "Application";
    categories = [ "Game" "RolePlaying" ];
    terminal = false;
  };

}