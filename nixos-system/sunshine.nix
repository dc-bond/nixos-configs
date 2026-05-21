{
  config,
  pkgs,
  lib,
  ...
}:

{

  # headless X session for game streaming
  # openbox provides a minimal WM so game windows can render and be focused
  services.xserver = {
    enable = true;
    # videoDrivers = ["nvidia"] already declared in nvidia.nix; composes cleanly
    extraConfig = ''
      Section "Device"
        Identifier "nvidia-virtual-display"
        Driver "nvidia"
        Option "AllowEmptyInitialConfiguration"  # init GPU without physical display connected
      EndSection
      Section "Screen"
        Identifier "screen0"
        DefaultDepth 24
        SubSection "Display"
          Depth 24
          Virtual 1920 1080
        EndSubSection
      EndSection
    '';
    windowManager.openbox.enable = true; # minimal WM; no DE needed for streaming-only host
  };

  # autologin chris at boot so the graphical session (and sunshine user service) starts without interaction
  services.xserver.displayManager.lightdm = {
    enable = true;
    autoLogin = {
      enable = true;
      user = "chris";
    };
  };
  services.displayManager.defaultSession = "none+openbox";

  # sunshine game streaming server (runs as user systemd service under chris's graphical session)
  # package pinned to pkgs-2505: 25.11 has a known crash regression on X11 capture
  # https://github.com/NixOS/nixpkgs/issues/475181 - remove pin once fixed upstream
  services.sunshine = {
    enable = true;
    autoStart = true;   # WantedBy = graphical-session.target; starts with chris's X session
    openFirewall = true; # opens ports 47984-47990, 48010
    # capSysAdmin omitted: only needed for KMS/DRM capture; X11 capture doesn't require it
    package = pkgs.pkgs-2505.sunshine;
    settings = {
      sunshine_name = "aspen";
    };
  };

  # uinput: required for sunshine to inject keyboard/mouse/gamepad events back to the host
  boot.kernelModules = [ "uinput" ];
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
  '';
  users.users.chris.extraGroups = [ "input" "uinput" ];

  # virtual audio: aspen has no physical audio hardware
  # pipewire with a null sink gives sunshine an audio device to capture and stream to clients
  # games write audio to the null sink; sunshine encodes it into the stream
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;    # sunshine uses the pulseaudio interface for audio capture
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

}
