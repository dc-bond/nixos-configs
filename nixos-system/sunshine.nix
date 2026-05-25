{
  pkgs,
  ...
}:

{

  services = {

    # headless X session for game streaming
    # videoDrivers = ["nvidia"] already declared in nvidia.nix; composes cleanly here
    # openbox is the minimal WM that gives game windows a surface to render into
    xserver = {
      enable = true;
      # deviceSection/monitorSection/screenSection inject into the NixOS-generated sections
      # that are wired to the ServerLayout — extraConfig adds orphaned sections Xorg ignores.
      #
      # ConnectedMonitor "DFP-0": tells NVIDIA to report the first digital output (DVI-D-0)
      # as connected even with no physical monitor.  SDL2 uses XRandR to enumerate available
      # displays; without a connected output it returns "No available displays" and
      # SDL_CreateWindow fails → no GL context → DrawInit_GL segfault.
      #
      # ModeValidation: bypass EDID checks that would reject the custom modeline because
      # there is no real monitor providing EDID data.
      #
      # AllowEmptyInitialConfiguration: fallback if the fake-connected CRTC fails to
      # initialise — allows X to start with a minimal config rather than aborting.
      deviceSection = ''
        Option "AllowEmptyInitialConfiguration"
        Option "ConnectedMonitor" "DFP-0"
        Option "ModeValidation" "NoEdidModes, NoDFPNativeResolutionCheck, NoVirtualSizeCheck, NoMaxSizeCheck, NoHorizSyncCheck, NoVertRefreshCheck, NoWidthAlignmentCheck"
      '';
      # Declare a synthetic 1920x1080 monitor so the Screen/Modes reference resolves.
      monitorSection = ''
        HorizSync 15-85
        VertRefresh 24-75
        Modeline "1920x1080_60" 172.800 1920 2040 2248 2576 1080 1081 1084 1118 -hsync +vsync
      '';
      # Put the CRTC into 1920x1080_60 at X startup so SDL2 sees the mode immediately,
      # without needing session-level xrandr commands.
      # Monitor "Monitor[0]" links explicitly to the monitorSection above so the
      # Modeline is reachable by the Modes "1920x1080_60" directive.
      screenSection = ''
        Monitor "Monitor[0]"
        DefaultDepth 24
        SubSection "Display"
          Depth 24
          Modes "1920x1080_60"
          Virtual 1920 1080
        EndSubSection
      '';
      windowManager.openbox.enable = true;
      displayManager.lightdm.enable = true;
    };

    displayManager = {
      defaultSession = "none+openbox"; # no DE, just openbox WM
      autoLogin = {
        enable = true;
        user = "chris"; # autologin so graphical-session.target (and sunshine) starts at boot
      };
    };

    # pinned to pkgs-2505: 25.11 has a known crash regression on X11 capture
    # https://github.com/NixOS/nixpkgs/issues/475181 - remove pin once fixed upstream
    sunshine = {
      enable = true;
      autoStart = true; # starts with chris's X session
      package = pkgs.pkgs-2505.sunshine;
      settings = {
        sunshine_name = "aspen";
      };
      applications = {
        env.PATH = "$(PATH):$(HOME)/.local/bin";
        apps = [
          {
            name = "Icewind Dale";
            cmd = "/etc/profiles/per-user/chris/bin/icewind-dale";
            image-path = "/home/chris/games/icewind-dale-ee/icon.png";
          }
          {
            name = "SNES";
            cmd = "/etc/profiles/per-user/chris/bin/retroarch-snes";
            image-path = "/home/chris/games/snes/icon.png";
          }
        ];
      };
    };

    # uinput device node permissions for sunshine input injection back to client
    udev.extraRules = ''
      KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
    '';

    # virtual audio: aspen has no physical audio hardware; audio.nix is not imported here
    # pipewire with a null sink gives sunshine an audio device to capture and stream to clients
    # security.rtkit (below) is the companion to pipewire and normally lives in audio.nix
    pipewire = {
      enable = true;
      audio.enable = true;
      pulse.enable = true; # sunshine uses the pulseaudio interface for audio capture
      wireplumber.enable = true;
      extraConfig.pipewire."99-sunshine-null-sink" = {
        "context.objects" = [
          {
            factory = "adapter";
            args = {
              "factory.name" = "support.null-audio-sink";
              "node.name" = "sunshine-null-sink";
              "node.description" = "Sunshine Game Streaming";
              "media.class" = "Audio/Sink";
              "audio.position" = "[ FL FR ]";
            };
          }
        ];
      };
    };

  };

  # PipeWire services are socket-activated by default: they start only when something first
  # uses the PipeWire socket.  Sunshine's stream startup is the first caller, so WirePlumber
  # (which manages the PA metadata needed for set-default-sink) starts at the same moment
  # Sunshine tries to call set-default-sink → PA_ERR_NOTSUPPORTED → no audio.
  # Fix: start all three eagerly with graphical-session.target so WirePlumber is fully
  # initialised well before any stream attempt.  Sunshine is also ordered after them so
  # it cannot race on first connect.
  systemd.user.services = {
    pipewire.wantedBy      = [ "graphical-session.target" ];
    pipewire-pulse.wantedBy = [ "graphical-session.target" ];
    wireplumber.wantedBy   = [ "graphical-session.target" ];
    sunshine = {
      after = [ "wireplumber.service" "pipewire-pulse.service" ];
      wants = [ "wireplumber.service" "pipewire-pulse.service" ];
    };
  };

  # uinput kernel module + group membership required for sunshine to inject input events
  boot.kernelModules = [ "uinput" ];
  users.users.chris.extraGroups = [ "input" ];
  security.rtkit.enable = true; # realtime scheduling priority for pipewire

  # no firewall rules needed: tailscale0 is fully trusted via tailscale.nix and sunshine only accessed through tailscale, so traffic never hits enp4s0 firewall

}
