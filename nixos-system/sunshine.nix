{
  pkgs,
  ...
}:

{

  services = {

    # headless x session for game streaming, openbox WM, nvidia driver from nvidia.nix
    xserver = {
      enable = true;
      # report DVI-D-0 as connected, bypass EDID checks, fall back if the fake CRTC fails
      deviceSection = ''
        Option "AllowEmptyInitialConfiguration"
        Option "ConnectedMonitor" "DFP-0"
        Option "ModeValidation" "NoEdidModes, NoDFPNativeResolutionCheck, NoVirtualSizeCheck, NoMaxSizeCheck, NoHorizSyncCheck, NoVertRefreshCheck, NoWidthAlignmentCheck"
      '';
      # synthetic 1920x1080 monitor so the screen/modes reference resolves
      monitorSection = ''
        HorizSync 15-85
        VertRefresh 24-75
        Modeline "1920x1080_60" 172.800 1920 2040 2248 2576 1080 1081 1084 1118 -hsync +vsync
      '';
      # set CRTC to 1920x1080_60 at x startup, Monitor[0] links to monitorSection for the modeline
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
        user = "chris"; # autologin so graphical-session.target and sunshine start at boot
      };
    };

    # pinned to pkgs-2505, 25.11 has a crash regression on x11 capture, see https://github.com/NixOS/nixpkgs/issues/475181
    sunshine = {
      enable = true;
      autoStart = true; # starts with chris's x session
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

    # uinput node permissions for sunshine input injection back to client
    udev.extraRules = ''
      KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
    '';

    # aspen has no physical audio hardware, sunshine loads its own null-sink at stream start
    pipewire = {
      enable = true;
      audio.enable = true;
      pulse.enable = true; # sunshine captures audio via the pulseaudio interface
      wireplumber.enable = true;
    };

  };

  # start pipewire and wireplumber eagerly with graphical-session.target so wireplumber is up before sunshine calls set-default-sink, sunshine ordered after them
  systemd.user.services = {
    pipewire.wantedBy      = [ "graphical-session.target" ];
    pipewire-pulse.wantedBy = [ "graphical-session.target" ];
    wireplumber.wantedBy   = [ "graphical-session.target" ];
    sunshine = {
      after = [ "wireplumber.service" "pipewire-pulse.service" ];
      wants = [ "wireplumber.service" "pipewire-pulse.service" ];
    };
  };

  # uinput kernel module and input group needed for sunshine input injection
  boot.kernelModules = [ "uinput" ];
  users.users.chris.extraGroups = [ "input" ];
  security.rtkit.enable = true; # realtime scheduling priority for pipewire

  # no firewall rules needed, tailscale0 is trusted via tailscale.nix and sunshine is only reached over tailscale

}
