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
    runtimeInputs = [ pkgs.steam-run pkgs.coreutils pkgs.pulseaudio ];
    text = ''
      if [ ! -f "${gameEntry}" ]; then
        echo "Icewind Dale EE not found at ${gameEntry}" >&2
        echo "Extract the GoG installer into ${gameDir} first." >&2
        exit 1
      fi
      cd "${gameDir}"
      chmod +x "${gameEntry}" # beamdog ships without the +x bit, idempotent

      # beamdog hardcodes ~/.local/share/<name>/ ignoring XDG_DATA_HOME, redirect via symlink
      mkdir -p "${gameDir}/userdata"
      mkdir -p "$HOME/.local/share" # tmpfs root, parent dir may not exist after a fresh reboot
      GAME_LINK="$HOME/.local/share/Icewind Dale - Enhanced Edition"
      if [ -L "$GAME_LINK" ]; then
        : # already a symlink, nothing to do
      elif [ -d "$GAME_LINK" ]; then
        echo "icewind-dale: migrating existing save data to ${gameDir}/userdata" >&2
        mv "$GAME_LINK" "${gameDir}/userdata"
        ln -s "${gameDir}/userdata" "$GAME_LINK"
      else
        ln -s "${gameDir}/userdata" "$GAME_LINK"
      fi

      # wait up to 5s for sunshine to create sink-sunshine-stereo and set it default before openAL opens audio
      for _ in 1 2 3 4 5 6 7 8 9 10; do
        if pactl list sinks short 2>/dev/null | grep -q "sink-sunshine-stereo"; then
          break
        fi
        sleep 0.5
      done

      # beamdog's SDL2 predates the wayland backend, force x11
      export SDL_VIDEODRIVER=''${SDL_VIDEODRIVER:-x11}
      # beamdog binary links libssl 1.0.0, pulled from pinned 21.05 nixpkgs
      export LD_LIBRARY_PATH=${pkgs.pkgs-2105.openssl_1_0_2.out}/lib:''${LD_LIBRARY_PATH:-}
      exec steam-run "${gameEntry}" "$@"
    '';
  };
in

{

  home.packages = [
    pkgs.steam-run # FHS chroot providing opengl, sdl2, openal, glibc for the beamdog binary
    iwdLauncher
  ];

  xdg.desktopEntries.icewind-dale = {
    name = "Icewind Dale: Enhanced Edition";
    comment = "Icewind Dale EE (Beamdog) via steam-run";
    exec = "${iwdLauncher}/bin/icewind-dale";
    icon = "${gameDir}/icon.png"; # 128x128 PNG alongside the game binary
    type = "Application";
    categories = [ "Game" "RolePlaying" ];
    terminal = false;
  };

}