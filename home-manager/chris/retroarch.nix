{
  pkgs,
  config,
  lib,
  ...
}:

let
  snesDir = "${config.home.homeDirectory}/games/snes";

  # build retroarch with snes9x core and settings baked in via wrapper (same mechanism
  # as programs.retroarch in the home-manager module, but done inline so the launcher
  # can reference the final package directly in runtimeInputs without circular dependency)
  retroarchWithSnes = pkgs.retroarch-bare.wrapper {
    cores = [ pkgs.libretro.snes9x ];
    settings = {
      # video: OpenGL on the headless NVIDIA virtual display; fullscreen so sunshine
      # captures the full 1920x1080 frame rather than a floating window
      video_driver              = "gl";
      video_fullscreen          = "true";
      video_windowed_fullscreen = "true"; # borderless — avoids exclusive-mode quirks on virtual display
      # audio: PipeWire pulse compat, same as IWD:EE
      audio_driver              = "pulse";
      audio_enable              = "true";
      # persist saves/states on ZFS, not ~/.config/retroarch
      savefile_directory        = "${snesDir}/saves";
      savestate_directory       = "${snesDir}/states";
      # input: udev for direct evdev (works headless without a DE); auto-map USB gamepads
      input_driver              = "udev";
      input_autodetect_enable   = "true";
      # default ROM browser path
      rgui_browser_directory    = "${snesDir}/roms";
    };
  };

  # launcher wraps retroarch with the same audio sink polling used by icewind-dale:
  # sunshine creates sink-sunshine-stereo on a separate thread; poll until it exists
  # so retroarch/pulse always opens the right device from the start
  retroarchLauncher = pkgs.writeShellApplication {
    name = "retroarch-snes";
    runtimeInputs = [ retroarchWithSnes pkgs.pulseaudio ];
    text = ''
      # poll up to 5 s for sunshine's audio sink before launching
      for _ in 1 2 3 4 5 6 7 8 9 10; do
        if pactl list sinks short 2>/dev/null | grep -q "sink-sunshine-stereo"; then
          break
        fi
        sleep 0.5
      done

      # headless X session is x11-only; be explicit to avoid env ambiguity
      export SDL_VIDEODRIVER=''${SDL_VIDEODRIVER:-x11}

      exec retroarch "$@"
    '';
  };

in

{

  home.packages = [
    retroarchWithSnes  # installs retroarch + snes9x to profile (direct invocation / RGUI)
    retroarchLauncher  # installs retroarch-snes wrapper (used by sunshine)
  ];

  xdg.desktopEntries.retroarch-snes = {
    name = "SNES (RetroArch)";
    comment = "Super Nintendo emulation via RetroArch/snes9x for Sunshine streaming";
    exec = "${retroarchLauncher}/bin/retroarch-snes";
    icon = "retroarch";
    type = "Application";
    categories = [ "Game" "Emulator" ];
    terminal = false;
  };

}