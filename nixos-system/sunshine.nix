{
  pkgs,
  ...
}:

{

  services = {

    # headless X session for game streaming
    # videoDrivers = ["nvidia"] already declared in nvidia.nix; composes cleanly here
    # AllowEmptyInitialConfiguration lets the NVIDIA driver init without a physical display connected
    # openbox is the minimal WM that gives game windows a surface to render into
    xserver = {
      enable = true;
      extraConfig = ''
        Section "Device"
          Identifier "nvidia-virtual-display"
          Driver "nvidia"
          Option "AllowEmptyInitialConfiguration"
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
      windowManager.openbox.enable = true;
      displayManager.lightdm.enable = true;
      # AllowEmptyInitialConfiguration defaults to 640x480 with no connected monitor.
      # Create a virtual 1920x1080 mode on DVI-D-0 at session start so games have a
      # usable display mode to initialise against. --newmode may fail if the mode
      # already exists (idempotent via || true).
      displayManager.sessionCommands = ''
        ${pkgs.xorg.xrandr}/bin/xrandr --newmode "1920x1080_60" 172.80 1920 2040 2248 2576 1080 1081 1084 1118 -hsync +vsync 2>/dev/null || true
        ${pkgs.xorg.xrandr}/bin/xrandr --addmode DVI-D-0 1920x1080_60 2>/dev/null || true
        ${pkgs.xorg.xrandr}/bin/xrandr --output DVI-D-0 --mode 1920x1080_60 --primary 2>/dev/null || true
      '';
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
      settings.sunshine_name = "aspen";
      applications = {
        env.PATH = "$(PATH):$(HOME)/.local/bin";
        apps = [
          {
            name = "Desktop";
            image-path = "desktop.png";
          }
          {
            name = "Icewind Dale EE";
            cmd = "/etc/profiles/per-user/chris/bin/icewind-dale";
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

  # uinput kernel module + group membership required for sunshine to inject input events
  boot.kernelModules = [ "uinput" ];
  users.users.chris.extraGroups = [ "input" ];
  security.rtkit.enable = true; # realtime scheduling priority for pipewire

  # no firewall rules needed: tailscale0 is fully trusted via tailscale.nix and sunshine only accessed through tailscale, so traffic never hits enp4s0 firewall

}
